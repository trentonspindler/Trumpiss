# 👑 The Nickname Project — Web

The web version of The Nickname Project: snap or upload a portrait and get a bold, presidential-grade nickname with a full personality breakdown. Same experience as the iOS app, running in any modern browser.

A **Liberty Lens Studios** production.

## How it works

- **Node + Express** server serves a single-page app and captures opt-in leads (`POST /api/lead`).
- **All photo analysis runs in the browser** — the image is never uploaded.
  - Real canvas pixel metrics: brightness, contrast, warmth, colorfulness, sharpness, symmetry.
  - Optional **face detection** via [`@vladmandic/face-api`](https://github.com/vladmandic/face-api) (loaded from CDN). If the models can't load, it gracefully falls back to pixel-only analysis.
- A deterministic, seeded nickname engine maps the signals onto six traits (Star Power, Energy, Charisma, Composure, Toughness, Class) and picks a brand-safe nickname. The same photo + name always yields the same result.

```
web/
├─ server.js            # Express server (static + /api/lead + /healthz)
├─ package.json
├─ Procfile             # web: node server.js
├─ railway.json         # Railway build/deploy + healthcheck config
└─ public/
   ├─ index.html        # All six screens
   ├─ styles.css        # Gold/navy brand theme
   ├─ app.js            # Flow, in-browser analysis, nickname engine
   ├─ legal.js          # Sample Terms & Privacy copy
   └─ favicon.svg
```

## Run locally

```bash
cd web
npm install
npm start
# open http://localhost:3000
```

> 📷 The live camera and the Web Share API require **HTTPS** (or `localhost`). On `localhost` everything works; on a deployed URL Railway provides HTTPS automatically. You can always use **Upload a Photo** instead of the camera.

## Deploy to Railway

**Option A — from a GitHub repo (easiest):**
1. Push this repo to GitHub.
2. On [railway.app](https://railway.app): **New Project → Deploy from GitHub repo** and pick this repo.
3. Set the service **Root Directory** to `web` (Settings → Source). This makes Railway build/run the app in this folder.
4. Railway auto-detects Node, runs `npm install`, and starts with `node server.js`. Click the generated domain — done.

**Option B — Railway CLI:**
```bash
npm i -g @railway/cli
railway login
cd web
railway init
railway up
```

### Notes
- **Port:** the server reads `process.env.PORT` (Railway sets this automatically). No config needed.
- **Health check:** `railway.json` points the healthcheck at `/healthz`.
- **Leads storage:** opt-in leads are appended to `data/leads.jsonl`. Railway's filesystem is **ephemeral**, so this is fine for a demo but resets on redeploy — attach a volume (and set `LEADS_FILE`) or wire up a database for production.

## ⚖️ Disclaimer

For **entertainment only**. Nicknames and "personality" readouts are algorithmically generated novelty content, not factual assessments. The bundled Terms and Privacy copy are **sample templates**, not legal advice.
