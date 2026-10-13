# Rhythm

A cross-platform music app prototype for iOS and Android, built with Expo + React Native + TypeScript.

## Current prototype
- Editorial interface with home, search, My Wave, library and settings
- Persistent mini-player and Now Playing modal
- Working persisted System/Dark/Light appearance and accent colors
- Blurred artwork background and active lyric-line emphasis inside the player
- A real public-domain traditional recording for playback testing (Wikimedia Commons); see [test media and attribution](docs/TEST_MEDIA.md)
- Other items are clearly labelled demo content

## Run
Requires Node.js LTS.

```bash
npm install
npx expo start
```

Scan the QR code with Expo Go or use an Android emulator.

## Important status
Only the Scarborough Fair test recording has a remote audio source. Live catalog search, licensed synchronized lyrics, a true personalized recommendation service, persistent likes/playlists/history, and production-ready provider integrations are not complete. The lyric timestamps are approximate UI-test values, not official synchronization metadata. The My Wave demo button does not claim to be a live recommendation service.

## Low-token development
Use Gemini Flash High for small scoped changes. Inspect only relevant files. Switch to Claude Sonnet only after two focused attempts fail on the same reproducible issue. Avoid full rewrites and don't claim tests/builds that were not run.

See [product specification](docs/PRODUCT_SPEC.md) and [implementation tasks](docs/ANTIGRAVITY_TASKS.md).
