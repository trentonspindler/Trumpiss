//
// The Nickname Project — client app
// A Liberty Lens Studios production.
//
// Flow: launch -> onboarding -> consent -> capture -> analyzing -> result.
// All photo analysis runs in the browser; the image never leaves the device.
//

"use strict";

/* ------------------------------------------------------------------ *
 * Tiny helpers
 * ------------------------------------------------------------------ */
const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => Array.from(document.querySelectorAll(sel));
const clamp01 = (v) => Math.min(1, Math.max(0, v));
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const U64 = (1n << 64n) - 1n;

const state = {
  profile: { fullName: "", email: "", marketingOptIn: false, agreedToTerms: false },
  imageEl: null,
  imageURL: null,
  stream: null,
  faceReady: false,
  faceLoadPromise: null,
  result: null,
};

function showScreen(id) {
  $$(".screen").forEach((s) => s.classList.remove("active"));
  $("#screen-" + id).classList.add("active");
  window.scrollTo({ top: 0, behavior: "instant" in window ? "instant" : "auto" });
}

function toast(msg) {
  const t = $("#toast");
  t.textContent = msg;
  t.classList.add("show");
  clearTimeout(toast._t);
  toast._t = setTimeout(() => t.classList.remove("show"), 2600);
}

/* ------------------------------------------------------------------ *
 * Deterministic PRNG (SplitMix64) + hashing
 * ------------------------------------------------------------------ */
function makeRng(seed) {
  let s = seed & U64;
  if (s === 0n) s = 0x9e3779b97f4a7c15n;
  return () => {
    s = (s + 0x9e3779b97f4a7c15n) & U64;
    let z = s;
    z = ((z ^ (z >> 30n)) * 0xbf58476d1ce4e5b9n) & U64;
    z = ((z ^ (z >> 27n)) * 0x94d049bb133111ebn) & U64;
    return (z ^ (z >> 31n)) & U64;
  };
}
const rngInt = (rng, n) => Number(rng() % BigInt(n));
const pick = (rng, arr) => arr[rngInt(rng, arr.length)];

function cyrb53(str, seed = 0) {
  let h1 = 0xdeadbeef ^ seed,
    h2 = 0x41c6ce57 ^ seed;
  for (let i = 0; i < str.length; i++) {
    const ch = str.charCodeAt(i);
    h1 = Math.imul(h1 ^ ch, 2654435761);
    h2 = Math.imul(h2 ^ ch, 1597334677);
  }
  h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507) ^ Math.imul(h2 ^ (h2 >>> 13), 3266489909);
  h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507) ^ Math.imul(h1 ^ (h1 >>> 13), 3266489909);
  return 4294967296 * (2097151 & h2) + (h1 >>> 0);
}
const nameSeed = (name) => BigInt(cyrb53(name.toLowerCase().trim(), 7)) & U64;

/* ------------------------------------------------------------------ *
 * Nickname engine (mirrors the iOS NicknameEngine)
 * ------------------------------------------------------------------ */
const STYLES = [
  {
    trait: "Star Power",
    prefixes: ["Big-League", "Tremendous", "Bigly", "The Powerful"],
    taglines: ["A presence you can feel from across the room.", "Born to stand in the spotlight."],
    verdicts: ['"Total star. Believe me, everybody\'s talking about it."', '"A face for the big stage. The biggest. Tremendous."'],
  },
  {
    trait: "Energy",
    prefixes: ["High-Energy", "Turbo", "Rocket", "The Unstoppable"],
    taglines: ["Pure momentum — never slows down.", "The kind of energy that wins."],
    verdicts: ['"So much energy. Incredible. We love the energy."', '"Always moving, always winning. Very high-energy person."'],
  },
  {
    trait: "Charisma",
    prefixes: ["Sunny", "Smilin'", "Cheerful", "The Bright"],
    taglines: ["A smile that closes the deal.", "Warmth that lights up the polls."],
    verdicts: ['"Great smile. People love this smile, frankly."', '"Such a likable face. Everybody says it. Tremendous charm."'],
  },
  {
    trait: "Composure",
    prefixes: ["Steady", "Cool-Hand", "The Sharp", "Ice-Cold"],
    taglines: ["Calm, sharp, and always in control.", "Never rattled. Always ready."],
    verdicts: ['"Very steady. Smart. A sharp cookie, this one."', '"Cool under pressure. The best people are calm like this."'],
  },
  {
    trait: "Toughness",
    prefixes: ["Iron", "Tough", "The Mighty", "Rock-Solid"],
    taglines: ["Built strong — impossible to push around.", "The toughest in the room, hands down."],
    verdicts: ['"Strong. Very strong. Tough as they come, believe me."', '"A real fighter\'s face. Nobody pushes this one around."'],
  },
  {
    trait: "Class",
    prefixes: ["Classy", "The Distinguished", "Five-Star", "The Elegant"],
    taglines: ["Old-school class, top to bottom.", "Pure elegance — first-class all the way."],
    verdicts: ['"Very classy. Top of the line. A first-class look."', '"Distinguished. Like a five-star resort, frankly the best."'],
  },
];
const SUFFIXES = [(n) => `${n}`, (n) => `${n} the Great`, (n) => `${n}, the Best`];

function displayName(name) {
  const first = (name || "").trim().split(/\s+/)[0] || "";
  if (!first) return "Champ";
  return first.charAt(0).toUpperCase() + first.slice(1).toLowerCase();
}

function computeTraits(m, rng) {
  const score = (base, jitter = 14) => {
    const noise = rngInt(rng, jitter * 2 + 1) - jitter;
    return Math.min(99, Math.max(42, Math.round(clamp01(base) * 100) + noise));
  };
  const starPower = m.faceFillRatio * 0.4 + m.captureQuality * 0.35 + m.contrast * 0.25;
  const energy = m.eyeOpenness * 0.4 + m.sharpness * 0.35 + m.colorfulness * 0.25;
  const charisma = m.smileScore * 0.6 + m.brightness * 0.25 + m.warmth * 0.15;
  const composure = m.symmetry * 0.6 + (1 - m.contrast * 0.5) * 0.4;
  const toughness = (1 - m.smileScore * 0.5) * 0.45 + m.contrast * 0.3 + (1 - m.brightness * 0.3) * 0.25;
  const classy = m.symmetry * 0.45 + m.captureQuality * 0.3 + m.brightness * 0.25;
  return [
    { name: "Star Power", value: score(starPower), icon: "⭐" },
    { name: "Energy", value: score(energy), icon: "⚡" },
    { name: "Charisma", value: score(charisma), icon: "😊" },
    { name: "Composure", value: score(composure), icon: "🧠" },
    { name: "Toughness", value: score(toughness), icon: "🛡️" },
    { name: "Class", value: score(classy), icon: "👑" },
  ];
}

function generate(m, name) {
  const rng = makeRng(m.seed ^ nameSeed(name));
  const traits = computeTraits(m, rng);
  const dominant = traits.reduce((a, b) => (b.value > a.value ? b : a));
  const style = STYLES.find((s) => s.trait === dominant.name) || STYLES[0];
  const prefix = pick(rng, style.prefixes);
  const display = displayName(name);
  const suffix = pick(rng, SUFFIXES)(display);
  const confidence = 78 + rngInt(rng, 21);
  return {
    nickname: `${prefix} ${suffix}`,
    tagline: pick(rng, style.taglines),
    verdict: pick(rng, style.verdicts),
    confidence,
    dominantTrait: dominant.name,
    traits: traits.slice().sort((a, b) => b.value - a.value),
  };
}

/* ------------------------------------------------------------------ *
 * Image analysis — pixel metrics (always) + face-api.js (if available)
 * ------------------------------------------------------------------ */
function pixelMetrics(imgEl) {
  const N = 128;
  const c = document.createElement("canvas");
  c.width = N;
  c.height = N;
  const ctx = c.getContext("2d", { willReadFrequently: true });
  ctx.drawImage(imgEl, 0, 0, N, N);
  const data = ctx.getImageData(0, 0, N, N).data;

  const lum = new Float32Array(N * N);
  let sum = 0, sumSq = 0, rSum = 0, bSum = 0, rg = 0, yb = 0;
  for (let i = 0, p = 0; i < data.length; i += 4, p++) {
    const r = data[i], g = data[i + 1], b = data[i + 2];
    const l = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    lum[p] = l;
    sum += l; sumSq += l * l; rSum += r; bSum += b;
    rg += Math.abs(r - g);
    yb += Math.abs(0.5 * (r + g) - b);
  }
  const n = N * N;
  const brightness = sum / n;
  const variance = Math.max(0, sumSq / n - brightness * brightness);
  const contrast = Math.min(1, Math.sqrt(variance) / 0.32);
  const warmth = clamp01((rSum - bSum) / n / 128 + 0.5);
  const colorfulness = Math.min(1, (rg / n + yb / n) / 180);

  let edge = 0, cnt = 0;
  for (let y = 1; y < N - 1; y++) {
    for (let x = 1; x < N - 1; x++) {
      const idx = y * N + x;
      const lap = 4 * lum[idx] - lum[idx - 1] - lum[idx + 1] - lum[idx - N] - lum[idx + N];
      edge += Math.abs(lap);
      cnt++;
    }
  }
  const sharpness = Math.min(1, edge / cnt / 0.12);

  let symDiff = 0, symCnt = 0;
  for (let y = 0; y < N; y++) {
    for (let x = 0; x < N / 2; x++) {
      symDiff += Math.abs(lum[y * N + x] - lum[y * N + (N - 1 - x)]);
      symCnt++;
    }
  }
  const symmetry = clamp01(1 - symDiff / symCnt / 0.5);

  return { brightness, contrast, warmth, colorfulness, sharpness, symmetry };
}

async function loadFaceApi() {
  if (typeof faceapi === "undefined") return false;
  const base = "https://cdn.jsdelivr.net/npm/@vladmandic/face-api/model";
  try {
    await Promise.race([
      Promise.all([
        faceapi.nets.tinyFaceDetector.loadFromUri(base),
        faceapi.nets.faceLandmark68Net.loadFromUri(base),
        faceapi.nets.faceExpressionNet.loadFromUri(base),
      ]),
      wait(9000).then(() => Promise.reject(new Error("timeout"))),
    ]);
    state.faceReady = true;
    return true;
  } catch (e) {
    console.warn("face-api unavailable — using pixel-only analysis.", e);
    return false;
  }
}

function regionOpenness(points) {
  if (!points || points.length < 4) return 0.5;
  const xs = points.map((p) => p.x), ys = points.map((p) => p.y);
  const w = Math.max(...xs) - Math.min(...xs);
  const h = Math.max(...ys) - Math.min(...ys);
  if (w <= 0) return 0.5;
  return Math.min(1, (h / w) * 2.2);
}

async function faceMetrics(imgEl) {
  if (!state.faceReady) return null;
  const det = await faceapi
    .detectSingleFace(imgEl, new faceapi.TinyFaceDetectorOptions({ inputSize: 320, scoreThreshold: 0.4 }))
    .withFaceLandmarks()
    .withFaceExpressions();
  if (!det) return { noFace: true };

  const box = det.detection.box;
  const imgArea = (imgEl.naturalWidth || imgEl.width) * (imgEl.naturalHeight || imgEl.height) || 1;
  const faceFillRatio = Math.min(1, ((box.width * box.height) / imgArea) * 1.6);
  const exp = det.expressions || {};
  const smileScore = Math.min(1, (exp.happy || 0) + (exp.surprised || 0) * 0.4);
  const lm = det.landmarks;
  const eyeOpenness = (regionOpenness(lm.getLeftEye()) + regionOpenness(lm.getRightEye())) / 2;
  const captureQuality = Math.min(1, det.detection.score || 0.6);

  // symmetry: balance of eyes around the nose tip
  let symmetry = 0.6;
  try {
    const le = lm.getLeftEye(), re = lm.getRightEye(), nose = lm.getNose();
    const cx = (p) => p.reduce((s, q) => s + q.x, 0) / p.length;
    const noseX = cx(nose), lX = cx(le), rX = cx(re);
    const ld = Math.abs(noseX - lX), rd = Math.abs(rX - noseX), tot = ld + rd;
    if (tot > 0) symmetry = clamp01(1 - Math.abs(ld - rd) / tot);
  } catch (_) {}

  return { faceFillRatio, smileScore, eyeOpenness, captureQuality, symmetry };
}

function buildSeed(m, name) {
  const key =
    [m.brightness, m.contrast, m.warmth, m.colorfulness, m.sharpness, m.symmetry, m.faceFillRatio, m.smileScore, m.eyeOpenness, m.captureQuality]
      .map((v) => Math.round(v * 1000))
      .join(",") +
    "|" +
    name.toLowerCase().trim();
  return ((BigInt(cyrb53(key, 1)) << 32n) ^ BigInt(cyrb53(key, 2))) & U64;
}

async function analyzePhoto(imgEl, name) {
  const px = pixelMetrics(imgEl);
  let fa = null;
  try {
    fa = await faceMetrics(imgEl);
  } catch (e) {
    console.warn("face detection failed; pixel fallback", e);
    fa = null;
  }
  if (fa && fa.noFace) {
    const err = new Error("noface");
    err.noFace = true;
    throw err;
  }
  const m = {
    brightness: px.brightness,
    contrast: px.contrast,
    warmth: px.warmth,
    colorfulness: px.colorfulness,
    sharpness: px.sharpness,
    symmetry: fa?.symmetry ?? px.symmetry,
    faceFillRatio: fa?.faceFillRatio ?? 0.5,
    smileScore: fa?.smileScore ?? clamp01(0.35 + px.warmth * 0.3),
    eyeOpenness: fa?.eyeOpenness ?? 0.55,
    captureQuality: fa?.captureQuality ?? clamp01(0.4 + px.sharpness * 0.5),
  };
  m.seed = buildSeed(m, name);
  return generate(m, name);
}

/* ------------------------------------------------------------------ *
 * Onboarding
 * ------------------------------------------------------------------ */
const SLIDES = [
  { icon: "📸", title: "Snap Your Portrait", body: "One photo is all our engine needs. Front camera, good light, and a confident look." },
  { icon: "🧠", title: "In-Browser Analysis", body: "We map dozens of facial and image signals right here in your browser. Your photo never leaves your device." },
  { icon: "✨", title: "Get Your Signature Nickname", body: "We translate your look into a bold, presidential-grade nickname — with a full personality breakdown." },
];
let slideIndex = 0;

function renderSlide() {
  const s = SLIDES[slideIndex];
  $("#onb-icon").textContent = s.icon;
  $("#onb-title").textContent = s.title;
  $("#onb-body").textContent = s.body;
  $("#onb-dots").innerHTML = SLIDES.map((_, i) => `<i class="${i === slideIndex ? "on" : ""}"></i>`).join("");
  $("#onb-next").textContent = slideIndex === SLIDES.length - 1 ? "Get Started" : "Continue";
}

/* ------------------------------------------------------------------ *
 * Consent
 * ------------------------------------------------------------------ */
function validEmail(e) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(e || "");
}
function refreshConsent() {
  const name = $("#in-name").value.trim();
  const email = $("#in-email").value.trim();
  state.profile.fullName = name;
  state.profile.email = email;
  state.profile.marketingOptIn = $("#opt-marketing").checked;
  state.profile.agreedToTerms = $("#opt-terms").checked;

  const emailOk = email === "" || validEmail(email);
  $("#err-email").classList.toggle("show", email !== "" && !emailOk);

  const ok = name.length > 0 && validEmail(email) && $("#opt-terms").checked;
  $("#consent-submit").disabled = !ok;
}

async function submitConsent() {
  $("#consent-submit").disabled = true;
  // Best-effort lead capture — the rest of the experience is client-side.
  try {
    await fetch("/api/lead", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(state.profile),
    });
  } catch (e) {
    console.warn("lead capture failed (continuing anyway):", e);
  }
  $("#capture-title").textContent = `Ready for your close-up, ${displayName(state.profile.fullName)}?`;
  showScreen("capture");
  startCamera();
}

/* ------------------------------------------------------------------ *
 * Capture
 * ------------------------------------------------------------------ */
function loadImage(url) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = url;
  });
}

async function startCamera() {
  if (state.stream) return;
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) return;
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: "user", width: { ideal: 1280 }, height: { ideal: 1280 } },
      audio: false,
    });
    state.stream = stream;
    const video = $("#cam-video");
    video.srcObject = stream;
    video.classList.remove("hidden");
    $("#capture-ph").classList.add("hidden");
  } catch (e) {
    console.warn("camera unavailable; upload fallback only", e);
  }
}

function stopCamera() {
  if (state.stream) {
    state.stream.getTracks().forEach((t) => t.stop());
    state.stream = null;
  }
  $("#cam-video").classList.add("hidden");
}

async function setCapturedImage(url) {
  if (state.imageURL && state.imageURL.startsWith("blob:")) URL.revokeObjectURL(state.imageURL);
  state.imageURL = url;
  state.imageEl = await loadImage(url);

  stopCamera();
  const preview = $("#cam-preview");
  preview.src = url;
  preview.classList.remove("hidden");
  $("#capture-ph").classList.add("hidden");
  $("#capture-error").classList.remove("show");

  $("#btn-shutter").classList.add("hidden");
  $("#btn-upload").classList.add("hidden");
  $("#btn-retake").classList.remove("hidden");
  $("#btn-analyze").classList.remove("hidden");
}

function resetCapture() {
  $("#cam-preview").classList.add("hidden");
  $("#btn-retake").classList.add("hidden");
  $("#btn-analyze").classList.add("hidden");
  $("#btn-shutter").classList.remove("hidden");
  $("#btn-upload").classList.remove("hidden");
  $("#capture-error").classList.remove("show");
  state.imageEl = null;
  startCamera();
}

function captureFromVideo() {
  const video = $("#cam-video");
  const w = video.videoWidth, h = video.videoHeight;
  const side = Math.min(w, h);
  const c = document.createElement("canvas");
  c.width = side;
  c.height = side;
  const ctx = c.getContext("2d");
  // Mirror so it matches the live selfie preview, center-cropped square.
  ctx.translate(side, 0);
  ctx.scale(-1, 1);
  ctx.drawImage(video, (w - side) / 2, (h - side) / 2, side, side, 0, 0, side, side);
  return c.toDataURL("image/jpeg", 0.92);
}

/* ------------------------------------------------------------------ *
 * Analyzing
 * ------------------------------------------------------------------ */
const STEPS = [
  "Detecting facial geometry…",
  "Mapping landmark points…",
  "Measuring star power & energy…",
  "Cross-referencing nickname matrix…",
  "Finalizing your verdict…",
];

async function runAnalysis() {
  showScreen("analyzing");
  $("#analyze-img").src = state.imageURL;

  let step = 0;
  $("#analyze-status").textContent = STEPS[0];
  const stepTimer = setInterval(() => {
    step = Math.min(step + 1, STEPS.length - 1);
    $("#analyze-status").textContent = STEPS[step];
  }, 640);

  try {
    const [result] = await Promise.all([
      analyzePhoto(state.imageEl, state.profile.fullName),
      wait(3200),
    ]);
    clearInterval(stepTimer);
    state.result = result;
    renderResult(result);
    showScreen("result");
  } catch (e) {
    clearInterval(stepTimer);
    showScreen("capture");
    const msg = e && e.noFace
      ? "We couldn't find a clear face in that photo. Make sure your face is well lit and centered, then try again."
      : "Something went wrong analyzing that photo. Please try again.";
    const box = $("#capture-error");
    box.textContent = msg;
    box.classList.add("show");
    resetCapture();
  }
}

/* ------------------------------------------------------------------ *
 * Result
 * ------------------------------------------------------------------ */
function renderResult(r) {
  $("#result-img").src = state.imageURL;
  $("#result-nickname").textContent = `“${r.nickname}”`;
  $("#result-tagline").textContent = r.tagline;
  $("#result-verdict").textContent = r.verdict;
  $("#result-dominant").textContent = `Dominant signal: ${r.dominantTrait}`;

  // Confidence ring + count-up
  const C = 207;
  const arc = $("#conf-arc");
  arc.style.transition = "none";
  arc.style.strokeDashoffset = C;
  const valEl = $("#conf-val");
  requestAnimationFrame(() => {
    arc.style.transition = "stroke-dashoffset 1s ease";
    arc.style.strokeDashoffset = C * (1 - r.confidence / 100);
  });
  let cur = 0;
  clearInterval(renderResult._t);
  renderResult._t = setInterval(() => {
    cur += 2;
    if (cur >= r.confidence) {
      cur = r.confidence;
      clearInterval(renderResult._t);
    }
    valEl.textContent = cur + "%";
  }, 18);

  // Trait bars
  $("#result-traits").innerHTML = r.traits
    .map(
      (t) => `
      <div class="trait">
        <div class="row"><span>${t.icon} ${t.name}</span><span class="v">${t.value}</span></div>
        <div class="bar"><i data-w="${t.value}"></i></div>
      </div>`
    )
    .join("");
  requestAnimationFrame(() =>
    setTimeout(() => $$("#result-traits .bar > i").forEach((el) => (el.style.width = el.dataset.w + "%")), 60)
  );
}

function shareText(r) {
  return `My signature nickname is “${r.nickname}” 👑\n${r.verdict}\nMatch confidence: ${r.confidence}%\n\nGet yours with The Nickname Project.`;
}

async function shareResult() {
  const text = shareText(state.result);
  if (navigator.share) {
    try {
      await navigator.share({ title: "The Nickname Project", text, url: location.href });
      return;
    } catch (_) {
      /* user cancelled */
      return;
    }
  }
  try {
    await navigator.clipboard.writeText(text + "\n" + location.href);
    toast("Copied to clipboard!");
  } catch (_) {
    toast("Sharing isn't supported on this device.");
  }
}

/* ------------------------------------------------------------------ *
 * Legal modal
 * ------------------------------------------------------------------ */
function openLegal(which) {
  const doc = window.LEGAL[which];
  $("#modal-title").textContent = doc.title;
  $("#modal-updated").textContent = window.LEGAL.updated;
  $("#modal-body").innerHTML =
    doc.sections.map(([h, b]) => `<h3>${h}</h3><p>${b}</p>`).join("") +
    `<p style="margin-top:14px;font-style:italic;" class="tertiary">This document is a sample template for demonstration and does not constitute legal advice.</p>`;
  $("#modal").classList.add("open");
}

/* ------------------------------------------------------------------ *
 * Wire-up
 * ------------------------------------------------------------------ */
function init() {
  // Kick off model loading in the background (non-blocking).
  state.faceLoadPromise = loadFaceApi();

  // Launch -> onboarding
  setTimeout(() => {
    renderSlide();
    showScreen("onboarding");
  }, 2400);

  // Onboarding
  $("#onb-next").addEventListener("click", () => {
    if (slideIndex < SLIDES.length - 1) {
      slideIndex++;
      renderSlide();
    } else {
      showScreen("consent");
    }
  });
  $("[data-skip]").addEventListener("click", () => showScreen("consent"));

  // Consent
  ["#in-name", "#in-email", "#opt-marketing", "#opt-terms"].forEach((sel) =>
    $(sel).addEventListener("input", refreshConsent)
  );
  $("#consent-submit").addEventListener("click", submitConsent);

  // Capture
  $("#btn-shutter").addEventListener("click", () => {
    if (state.stream) {
      setCapturedImage(captureFromVideo());
    } else {
      const fi = $("#file-input");
      fi.setAttribute("capture", "user");
      fi.click();
    }
  });
  $("#btn-upload").addEventListener("click", () => {
    const fi = $("#file-input");
    fi.removeAttribute("capture");
    fi.click();
  });
  $("#file-input").addEventListener("change", (e) => {
    const file = e.target.files && e.target.files[0];
    if (file) setCapturedImage(URL.createObjectURL(file));
    e.target.value = "";
  });
  $("#btn-retake").addEventListener("click", resetCapture);
  $("#btn-analyze").addEventListener("click", runAnalysis);

  // Result
  $("#btn-share").addEventListener("click", shareResult);
  $("#btn-startover").addEventListener("click", () => {
    resetCapture();
    showScreen("capture");
  });

  // Legal modal
  $$("[data-open]").forEach((el) => el.addEventListener("click", () => openLegal(el.dataset.open)));
  $("[data-close]").addEventListener("click", () => $("#modal").classList.remove("open"));
  $("#modal").addEventListener("click", (e) => {
    if (e.target.id === "modal") $("#modal").classList.remove("open");
  });
}

document.addEventListener("DOMContentLoaded", init);
