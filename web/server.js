//
// The Nickname Project — web server
// A Liberty Lens Studios production.
//
// Minimal Express server: serves the static single-page app and captures
// opt-in leads. Photo analysis happens entirely in the browser, so no image
// ever touches the server.
//

import express from "express";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { promises as fs } from "fs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = process.env.PORT || 3000;

// Where opt-in leads are appended. NOTE: most hosts (including Railway) use an
// ephemeral filesystem, so this is fine for a demo but use a real database for
// production. Override with LEADS_FILE if you mount a volume.
const LEADS_FILE = process.env.LEADS_FILE || join(__dirname, "data", "leads.jsonl");

app.use(express.json({ limit: "64kb" }));
app.use(
  express.static(join(__dirname, "public"), {
    maxAge: "1h",
    setHeaders: (res) => res.setHeader("Cache-Control", "public, max-age=3600"),
  })
);

// Health check (handy for Railway/uptime monitors).
app.get("/healthz", (_req, res) => res.json({ ok: true, service: "nickname-project" }));

// Capture an opt-in lead (name + email + consent flags). The photo is never sent.
app.post("/api/lead", async (req, res) => {
  try {
    const { fullName, email, marketingOptIn, agreedToTerms } = req.body || {};

    if (!fullName || typeof fullName !== "string" || !fullName.trim()) {
      return res.status(400).json({ error: "A name is required." });
    }
    if (!isValidEmail(email)) {
      return res.status(400).json({ error: "A valid email is required." });
    }
    if (agreedToTerms !== true) {
      return res.status(400).json({ error: "You must agree to the Terms and Privacy Policy." });
    }

    const record = {
      fullName: String(fullName).trim().slice(0, 120),
      email: String(email).trim().toLowerCase().slice(0, 200),
      marketingOptIn: marketingOptIn === true,
      agreedToTerms: true,
      consentAt: new Date().toISOString(),
      ip: req.headers["x-forwarded-for"] || req.socket.remoteAddress || null,
      userAgent: req.headers["user-agent"] || null,
    };

    await fs.mkdir(dirname(LEADS_FILE), { recursive: true });
    await fs.appendFile(LEADS_FILE, JSON.stringify(record) + "\n", "utf8");

    res.json({ ok: true });
  } catch (err) {
    console.error("Failed to record lead:", err);
    res.status(500).json({ error: "Could not save your details. Please try again." });
  }
});

function isValidEmail(email) {
  return typeof email === "string" && /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email);
}

app.listen(PORT, () => {
  console.log(`The Nickname Project is live on http://localhost:${PORT}`);
});
