# Rhythm

Rhythm is a cross-platform music app prototype for iOS and Android, built with Expo + React Native + TypeScript.

## Current prototype
- Custom editorial interface with persistent mini-player and bottom navigation
- Home, search, My Wave, library and settings tabs
- Working persisted System/Dark/Light appearance and accent color settings
- Now Playing modal with blurred artwork and active lyric-line emphasis
- Clearly labelled demo data, not a live catalog

## Run
Requires Node.js LTS.

```bash
npm install
npx expo start
```

Scan the QR code with Expo Go or use an Android emulator.

## Important status
Playback, live catalog search, timestamped licensed lyrics, and true personalized recommendations are not connected yet. The current player only simulates a position for UI testing; the demo wave does not claim to be a live recommendation service. Providers must be integrated using their official APIs and terms.

## Low-token development
Use Gemini Flash High for small scoped changes. Ask it to inspect only files relevant to one task. Switch to Claude Sonnet only after two focused attempts fail on the same reproducible issue. Avoid full rewrites and don't claim tests/builds that were not run.

See [product specification](docs/PRODUCT_SPEC.md) and [implementation tasks](docs/ANTIGRAVITY_TASKS.md).
