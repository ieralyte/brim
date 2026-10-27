# Roadmap

Each milestone ends with a tagged GitHub release. The riskiest work (private Apple APIs) comes early.

## v0.1 — Notch shell ✅
- [x] Panel over the notch on every Space, including full-screen apps
- [x] Expands on hover, collapses after the pointer leaves
- [x] Clicks pass through while closed
- [x] Repositions when displays change; fallback pill without a notch
- [x] Menu bar item, no Dock icon

## v0.2 — Now Playing ✅
- [x] Title, artist and artwork for Apple Music, Spotify, Tidal and browsers (via mediaremote-adapter)
- [x] Play/pause, next, previous and a scrubber
- [x] Compact live state while collapsed

## v0.3 — File tray and battery ✅
- [x] Drag files onto the notch to hold them; drag them back out
- [x] Tray survives restarts
- [x] Charging animation, low-battery alerts at 20% and 10%

## v0.4 — Lock screen ✅
- [x] Now Playing and battery on the lock screen (SkyLight)
- [x] Hidden immediately on unlock
- [x] Off switch in Settings; graceful fallback if private APIs fail

## v0.5 — Release pipeline ✅
- [x] GitHub Actions builds an ad-hoc signed DMG on each `v*` tag
- [x] Homebrew tap (`homebrew-brim`) updated automatically
- [x] Install guide for the Gatekeeper prompt

## v1.0 — Public launch ✅
- [x] Every box above ticked
- [x] Diagnostics panel in Settings
- [x] README demo GIF
- [x] Launch at login, floating pill on displays without a notch
- [x] Public repo and Homebrew tap

## v1.1 — Live lyrics
- [ ] Time-synced lyrics from LRCLIB in the notch and on the lock screen (opt-in)

## Later
- AirPods battery, weather, calendar, audio output picker, external displays
