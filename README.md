# Rhythm

A new cross-platform music app for iOS and Android.

This repository is the clean rewrite of Rhythm. The existing `isnoth1ng-prog/rhythm` repository is separate and is not part of this project.

## Product direction

Build a polished music discovery and playback experience with an original visual identity. Work in small steps that are easy to run, review, and continue with a different model if needed.

See [docs/PRODUCT_SPEC.md](docs/PRODUCT_SPEC.md) for the current scope and implementation phases.

## Working principles

- The owner is a beginner; keep setup and explanations clear.
- Implement one small phase at a time. Do not generate the whole app in one pass.
- Keep UI, catalog/search, playback, and provider integrations behind clear boundaries.
- Keep secrets out of source control.
- Use only provider-supported APIs and playback methods. Verify current official terms and playback limits before implementing a provider.
- After each task, report changed files, key decisions, commands/checks run, and the next small step.
- Model choice is flexible. Prefer a cost-conscious capable model such as Gemini 3.8 Flash High for routine work when available; use Claude Sonnet 4.6 for difficult debugging or unusually complex decisions. Never assume a model is available, and keep handoffs self-contained.
