# 👑 The Nickname Project

> *AI-powered portrait branding.* Snap a photo and discover the bold, presidential-grade nickname your look earns you — complete with a full personality breakdown.
>
> A **Liberty Lens Studios** production.

The Nickname Project is a polished app that takes a portrait, analyzes it **on-device / in-browser**, and generates a playful, Trump-style signature nickname along with a confidence score and a six-trait personality breakdown.

It ships in two flavors:

| Flavor | Path | Stack | Best for |
| --- | --- | --- | --- |
| 📱 **Native iOS app** | [`/` (this folder)](Trumpiss.xcodeproj) | SwiftUI + Vision | Running on a real iPhone via Xcode |
| 🌐 **Web app** | [`/web`](web/) | Node + Express + vanilla JS | Deploying a shareable link (e.g. Railway) — **no Mac required** |

> **Just want a link you can open on any phone?** Use the web app in [`/web`](web/) — it has its own README with one-click Railway deploy steps.

---

## 📱 iOS app

A native SwiftUI app that takes a portrait, analyzes it **entirely on-device** using Apple's Vision framework, and generates the nickname + breakdown.

---

## ✨ Features

- **Cinematic, studio-grade UI** — branded splash, paged onboarding, glass cards, gold/navy theme, and haptics throughout.
- **Profile & consent flow** — collects name + email and records explicit **marketing opt-in** and **Terms / Privacy** consent *before* any photo is taken, with sample legal documents included.
- **Camera & library capture** — take a new selfie (front camera) or pick an existing portrait.
- **On-device facial analysis** — `FaceAnalyzer` uses Vision face landmarks, capture-quality, symmetry, smile, eye-openness and brightness signals. **No photo ever leaves the device.**
- **Deterministic nickname engine** — `NicknameEngine` maps the measured signals onto six traits (Star Power, Energy, Charisma, Composure, Toughness, Class) and selects a brand-safe nickname family. The same photo + name always yields the same result.
- **Shareable results** — a big reveal screen with the nickname, a "verdict" quote, animated confidence ring, trait bars, and a native share sheet.

## 🧱 Project structure

```
Trumpiss/
├─ Trumpiss.xcodeproj/          # Xcode 16 project (file-system synchronized)
└─ Trumpiss/
   ├─ TrumpissApp.swift         # App entry point
   ├─ Support/Theme.swift       # Brand colors, type, haptics
   ├─ Models/Models.swift       # UserProfile, TraitScore, NicknameResult
   ├─ Services/
   │  ├─ AppState.swift         # Flow state machine + persistence
   │  ├─ FaceAnalyzer.swift     # Vision-based on-device analysis
   │  └─ NicknameEngine.swift   # Deterministic nickname/trait generation
   ├─ Views/
   │  ├─ RootView.swift         # Phase router
   │  ├─ LaunchView.swift       # Branded splash
   │  ├─ OnboardingView.swift   # Value-prop walkthrough
   │  ├─ ConsentView.swift      # Name/email + marketing & terms consent
   │  ├─ LegalView.swift        # Sample Terms & Privacy documents
   │  ├─ CaptureView.swift      # Camera / library capture
   │  ├─ ImagePicker.swift      # UIImagePickerController bridge
   │  ├─ AnalyzingView.swift    # Cinematic progress experience
   │  ├─ ResultView.swift       # The reveal + sharing
   │  └─ Components.swift       # Reusable buttons, cards, pills
   └─ Assets.xcassets/          # App icon + accent color
```

## 🚀 Getting started

**Requirements:** Xcode 16+, iOS 17+ device or simulator.

1. Open `Trumpiss.xcodeproj` in Xcode.
2. Select the **Trumpiss** scheme and a simulator or your device.
3. Press **Run** (⌘R).

> 📸 The camera is only available on a physical device. In the Simulator, use **Choose from Library** instead.

The bundle identifier is `com.libertylensstudios.Trumpiss`. To run on a physical device, select your development team under **Signing & Capabilities** (automatic signing is enabled).

## 🔐 Privacy

All image processing happens locally via the Vision framework — photos are never uploaded or stored on a server. The only data persisted is the name/email you enter (in `UserDefaults`) and your consent choices.

## ⚖️ Disclaimer

This app is for **entertainment purposes only**. Nicknames and "personality" readouts are algorithmically generated novelty content and are not factual assessments. The bundled Terms of Service and Privacy Policy are **sample templates** for demonstration and are not legal advice — consult an attorney before shipping.
