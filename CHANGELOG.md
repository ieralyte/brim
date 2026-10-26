# Changelog

All notable changes to Brim are listed here, newest first.

## [0.5.1] - 2026-10-27

### Added
- App icon: BRIM in a live-activity pill on graphite, with a simplified "b" mark at the smallest sizes. Sources in `design/`.

## [0.5.0] - 2026-10-27

### Added
- Release workflow: pushing a version tag builds Brim on GitHub Actions, packages a DMG and publishes a GitHub Release with these notes.
- Homebrew tap (`ieralyte/homebrew-brim`), updated automatically on each release.
- `scripts/make-dmg.sh` builds the same DMG locally.
- Install and release instructions in the README.

## [0.4.0] - 2026-10-27

### Added
- Lock screen card: Now Playing with artwork and controls, plus battery level, shown below the clock while the Mac is locked, whether the track is playing or paused. When nothing is loaded it shows a small battery pill.
- The card disappears the moment the Mac unlocks.
- Settings → "Show on lock screen" turns it off; Diagnostics shows whether it is working.

## [0.3.0] - 2026-10-27

### Added
- File tray: drag files onto the notch to hold them and drag them back out. Double-click opens a file; hover to remove one, or clear them all. The tray survives restarts.
- Charging notice in the closed island when you plug in, and low-battery alerts at 20% and 10%.
- Battery level in the top corner of the open island.
- Settings → Diagnostics shows battery status and can preview the alerts.

### Changed
- The open island is wider, with Now Playing on the left and the tray on the right.
- The island stays open while the mouse button is held, so files can be dragged out of it.

## [0.2.0] - 2026-10-27

### Added
- Now Playing: title, artist and artwork for Apple Music, Spotify, Tidal and browser players.
- Play/pause, previous and next controls, and a scrubber that grows while you drag it.
- Live activity in the closed island while music plays: artwork left of the notch, an animated waveform right of it.
- Settings → Diagnostics shows whether Now Playing is working.
- Bundles mediaremote-adapter (BSD 3-Clause) to reach Now Playing on macOS 15.4 and later.

### Changed
- The island closes faster when the pointer leaves.

## [0.1.0] - 2026-10-27

### Added
- Notch shell: a transparent panel over the notch that expands on hover and collapses when the pointer leaves.
- Menu bar item with Settings and Quit; no Dock icon.
- Fallback pill on displays without a notch.
