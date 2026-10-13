# Antigravity workflow — low token usage

## Model policy
- Default: Gemini Flash High.
- Use one task per prompt. Keep prompts limited to named files and acceptance criteria.
- Switch to Claude Sonnet Thinking only after two focused attempts fail on the same reproducible bug or when a difficult architecture decision is required.
- Avoid Opus for routine work.
- Never ask a model to rewrite the whole repository, dump every file, or repeatedly inspect unrelated files.
- After each task, ask for: files changed, commands run, actual results, unresolved issues. Do not accept claimed tests/builds that were not run.

## Task 1 — app shell
Read `docs/PRODUCT_SPEC.md`. Inspect the existing project structure. Build the smallest complete Expo React Native + TypeScript app if no app exists yet. Implement edge-to-edge layout, bottom tabs, persistent mini-player and a Now Playing modal/sheet. Do not integrate real providers yet. Add loading/error/empty states. Use custom editorial visual styling, not default Material UI. Keep changes scoped and run TypeScript checks if available.

## Task 2 — themes
Implement System/Dark/Light appearance and accent palette as persistent state. Verify the setting updates all screens, mini-player, modal, icons and status/navigation bar styling. Do not add unrelated settings.

## Task 3 — lyrics
Embed lyrics within Now Playing. Use blurred artwork behind the lyrics and a gradient for legibility. Highlight only the active timestamped lyric line; fade neighboring lines. Keep lyrics in the player and do not create a separate lyrics page. Use public-domain test lyrics or licensed lyric data only.

## Task 4 — dynamic My Wave
Create a recommendation queue contract that requests the next track dynamically from a provider. Add deduplication, recent-history exclusion, skip/like feedback and a labelled development adapter. Never represent a hardcoded fixture list as a live personalized recommendation engine. Provider-specific APIs are a separate task.

## Task 5 — search and source adapters
Create normalized search ranking and provider interfaces. Rank exact artist/title matches above loose matches. Filter likely unrelated karaoke/slowed/sped-up/reaction uploads when the user wants the original. Keep metadata and playable stream capabilities separate. Follow official provider API terms; never extract YouTube audio streams.

## Task 6 — sample media
Use only a licensed royalty-free audio sample or a public-domain recording, with source and license recorded in `docs/TEST_MEDIA.md`. Use public-domain test lyrics. Clearly label sample/demo media in the UI. Do not use a copyrighted commercial track or reproduce its lyrics without permission.

## Task 7 — verification
Run the checks actually available. Report the exact command and output. Fix only concrete errors. Keep each fix small.
