# Changelog

All notable changes to Brim are listed here, newest first.

## [1.0.0] - 2026-10-28

The first public release: Brim is open source on GitHub and installs with `brew install --cask ieralyte/brim/brim`.

### Added
- Third-party notices (mediaremote-adapter, SkyLightWindow, Outfit), in the repo and inside the app.
- README: lock screen photo.

### Security
- Release workflow: the Homebrew token is only given to the step that updates the tap, and third-party actions are pinned to exact commits.

## [0.5.4] - 2026-10-28

### Changed
- Xcode's recommended project settings (dead code stripping, standard compiler warnings).
- README: screenshots and a demo GIF.

### Fixed
- The lock screen card could stay unavailable until Brim was restarted, for example when Brim started at login. Setup now tolerates harmless errors from macOS, retries on every lock, and Settings → Diagnostics shows the reason if it still fails.

## [0.5.3] - 2026-10-28

### Added
- Settings → "Start Brim at login", using macOS's login item service. If macOS asks for approval, Settings links straight to Login Items.

### Changed
- On displays without a notch (external monitors, a closed MacBook lid), the island is a floating pill just below the top edge, like the Dynamic Island, instead of a fake notch. It stays hidden while idle and appears on hover, while music plays, and for battery alerts.
- The app icon uses the full BRIM design at every size, including Finder lists and Login Items.

### Fixed
- On Macs without a notch, Brim now always uses the main display (the one with the menu bar). It used to follow whichever screen had focus when displays changed.

## [0.5.2] - 2026-10-27

### Added
- Settings → "Keep the screen on while locked": Never, While music is playing (default) or Always, optionally only when plugged in. macOS otherwise turns the lock screen off after about 30 seconds.
- Song progress bar on the lock screen card, with elapsed and remaining time; drag it to seek.

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
