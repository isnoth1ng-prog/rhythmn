# Rhythm — product specification

## Product direction
Rhythm is a polished iOS and Android music app with an iOS-first visual sensibility: editorial typography, artwork-led layouts, deep matte surfaces, restrained glass, careful motion, custom iconography and deliberate spacing. Avoid default Android/Material visual styling.

## Must-have UX
1. **Edge-to-edge:** app surfaces extend behind system bars where supported. Respect insets for interactive controls but avoid blank top/bottom bands. System bars match the active theme.
2. **Persistent mini-player:** visible above bottom navigation across tabs. Tapping opens a Now Playing modal/sheet, never a separate player tab.
3. **Lyrics inside Now Playing:** full-bleed blurred artwork background, readable gradient overlay, vertical lyric flow. Only the current timestamped line is emphasized; other lines are visually softened. Lyrics do not open a separate window. Never invent timestamps.
4. **Themes:** System/Dark/Light across every screen, sheet, control, mini-player and system bar. Accent color is independent and updates selected controls, progress and active lyric line.
5. **My Wave:** dynamic queue that asks a recommendation provider for new tracks as playback advances, informed by likes, skips, listening history and seeds. Deduplicate and avoid recent repeats. A demo adapter must be clearly labelled and must not pretend a fixed fixture list is personalization.
6. **Search quality:** normalize case, punctuation, whitespace and artist/title variants; rank exact artist/title matches first. De-prioritize likely karaoke, sped-up, slowed, nightcore, reaction and unrelated uploads when looking for originals. Never claim “official” without provider evidence.
7. **Design quality:** consistent icon stroke weights, refined buttons and touch targets, polished transitions, loading/empty/error states.
8. **Settings:** appearance and accent selection must persist. Other settings should be marked unavailable until implemented.
9. **Library:** likes, playlists, history and recently played should persist locally.
10. **Accessibility:** accessible labels, contrast, scalable text and reduced-motion consideration.

## Music-source rules
- Use official APIs/SDKs and licensed/public-domain/demo audio.
- YouTube Data API search provides metadata but does not permit extracting an audio-only stream. YouTube playback must use an approved player/flow and comply with developer policies.
- SoundCloud playback depends on API access, track eligibility, attribution and current platform terms.
- Separate metadata availability from playable audio. Do not claim a preview is full playback.
- Lyrics should come from a legitimate source or public-domain material. Do not bundle copyrighted lyrics without permission.

## Current prototype status
The app shell, tabs, theme/accent state, mini-player UI, Now Playing sheet, demo search and sample lyric styling are being implemented. Playback, live catalog, recommendation service, persisted library and licensed synced lyrics are not yet complete. UI demo controls must not claim to be real streaming.

## Milestones
A. Buildable Expo shell and refined UI.
B. Theme/accent persistence and edge-to-edge layout.
C. Mini-player and Now Playing sheet with blurred lyric treatment.
D. Dynamic recommendation provider contract for My Wave.
E. Search adapters and result ranking.
F. Real playback from permitted sources with honest playback state.
G. Local library/history/likes, tests and EAS builds.

## Acceptance criteria
- No blank top/bottom bands caused by layout.
- Mini-player persists across tabs and player is a modal.
- Lyrics appear inside the player and only the current timestamped line is emphasized.
- Dark/Light changes the entire app and system bars; accent updates all interactive highlights.
- My Wave requests recommendations dynamically once provider integration is implemented.
- Demo content is clearly labelled.
- Errors and blocked tracks are handled honestly.
