# Rhythm — Product Specification

## Product goal

Create a new Rhythm music app for iOS and Android. This repository, `isnoth1ng-prog/rhythmn`, is the source of truth for the rewrite. Do not make changes to the existing `isnoth1ng-prog/rhythm` repository.

The owner is new to app development and wants to grow a real product gradually with AI assistance. Keep each implementation task small, understandable, runnable, and reviewable.

## Confirmed direction

- Platforms: iPhone/iOS and Android.
- Music comes from internet streaming.
- YouTube and SoundCloud are candidate sources, not yet approved technical choices.
- Search should surface useful tracks with artist/creator and title metadata and filter obvious junk where supported metadata allows.
- Create a distinct visual style for Rhythm.
- Build progressively, starting with the smallest useful foundation.
- The owner may switch the project to Gemini or Claude Sonnet 4.6 when needed; each phase must have a concise, self-contained handoff.

## Provider and rights constraints

Before implementing a music source, check its current official API documentation, playback requirements, attribution/branding rules, and terms. Use documented, supported playback and discovery flows only. Do not scrape, extract audio, bypass access controls, or imply third-party music is licensed for redistribution. Keep providers behind an interface so the app can adapt if a candidate source does not support the intended experience.

If neither YouTube nor SoundCloud supports the desired use case under its current terms and technical limits, explain the limitation and identify a compliant alternative before building the integration.

## Decisions still open

- Cross-platform framework and minimum OS versions.
- MVP provider and exact playback capabilities.
- Backend, accounts, and whether they are needed for the first release.
- Visual identity, launch region, and monetization.
- Search ranking and junk-result filtering rules.

Make decisions only when needed for the next phase. Explain choices plainly and avoid unnecessary infrastructure.

## Implementation phases

### Phase 0 — Inspect and choose the foundation
Inspect the repository and development environment. Compare suitable cross-platform stacks against the owner's actual setup, recommend one, and record the decision in a short architecture note. Check current official provider documentation for feasibility before recommending an initial provider. Do not scaffold until the recommendation is clear.

**Done when:** the stack and first provider-feasibility plan are documented, with a short setup checklist.

### Phase 1 — Minimal app shell
Scaffold the chosen app and add one home screen with sample data, an original visual foundation, and iOS/Android targets. Provide beginner-friendly run instructions. No real streaming yet.

**Done when:** it launches on at least one available target and the next step is clear.

### Phase 2 — Search and catalog boundary
Define provider-neutral track/search models, a provider interface, and a search screen using fixtures. Decide how missing or low-quality metadata is filtered and communicate filtered results clearly.

**Done when:** search works with fixtures and provider details stay out of UI code.

### Phase 3 — First provider proof of concept
Re-check official docs and terms. Select one feasible provider and implement its documented supported discovery/embed/playback path, including loading, empty, and error states. Keep credentials/configuration out of source control.

**Done when:** a compliant end-to-end proof of concept works and its limitations are documented.

### Phase 4 — Playback experience
Add supported player state, queue, play/pause, and seek where available. Add background audio and interruption handling only where permitted. Handle network loss and unsupported tracks.

**Done when:** playback matches provider capabilities and errors are understandable.

### Phase 5 — Library and persistence
Decide whether accounts are needed. Add saved tracks/playlists and persistence only after privacy and provider decisions. Document data handling and account deletion needs before adding a backend.

**Done when:** selected library features persist reliably and privacy behavior is documented.

### Phase 6 — Hardening and release
Review accessibility, performance, crashes, platform permissions, store policies, provider attribution, and support/update workflow. Add automated checks when they provide clear value.

**Done when:** release blockers and known limitations are documented.

## AI handoff protocol

- Work only on the current phase and relevant files.
- Before broad edits, give a short plan; prefer small diffs.
- Do not generate the whole application in one prompt.
- After each task, summarize changed files, decisions, commands/checks run, and the next task.
- Keep prompts self-contained so work can continue if the model changes.
- Use the cost-conscious capable default available to the owner for routine implementation. Consider Gemini 3.8 Flash High when available; reserve Claude Sonnet 4.6 for difficult debugging or complex decisions. Do not use expensive models or run large builds without a concrete need.
