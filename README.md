<p align="center"><img src="docs/images/icon.png" width="128" height="128" alt="Brim app icon"></p>

# Brim

A free, open-source Dynamic Island for MacBooks. Brim turns the notch into a live strip for media, files and battery status, and puts Now Playing on your lock screen.

> **Status: v0.5, early development.** See [the roadmap](docs/ROADMAP.md).

## Features

- **Hover to open.** The notch expands into an island and closes as soon as the pointer leaves.
- **Now Playing.** Artwork, title, artist, a scrubber and controls for Apple Music, Spotify, Tidal and browser players. While music plays, the closed island shows the artwork and a live waveform.
- **File tray.** Drag files onto the notch to hold them, then drag them out wherever you need them. Double-click to open; the tray survives restarts.
- **Battery.** A brief charging notice when you plug in, low-battery alerts at 20% and 10%, and the battery level in the open island.
- **Lock screen.** Now Playing with controls, and your battery level, before you log in. Brim can keep the lock screen lit while music plays (or always), instead of macOS turning it off after about 30 seconds. Both are in Settings.

## Requirements

- macOS 26 Tahoe or later
- A Mac with Apple silicon (notched MacBooks get the full effect; other displays show a small pill)
- Xcode 26 to build from source

## Build and run

```sh
git clone https://github.com/ieralyte/brim.git
cd brim
open Brim.xcodeproj
```

Press **Run** (⌘R) in Xcode. No Apple Developer account is needed: the project signs locally ("Sign to Run Locally").

Brim has no Dock icon. Look for its icon in the menu bar for Settings and Quit, then hover over the notch.

From the command line:

```sh
xcodebuild -project Brim.xcodeproj -scheme Brim -configuration Release build
```

## Install

**Homebrew**

```sh
brew install --cask ieralyte/brim/brim
```

**Download**

Get `Brim-<version>.dmg` from [Releases](https://github.com/ieralyte/brim/releases), open it and drag Brim to Applications.

**First launch**

Brim is free and isn't notarized by Apple, so macOS blocks it the first time:

1. Open Brim. macOS says it can't verify the developer; click **Done**.
2. Open **System Settings → Privacy & Security**, scroll down and click **Open Anyway** next to Brim.
3. Open Brim again and confirm. You only do this once per version.

Brim has no Dock icon: look for it in the menu bar, then hover over the notch.

## Releasing

Releases are built by GitHub Actions (`.github/workflows/release.yml`) whenever a version tag is pushed:

1. Bump `MARKETING_VERSION` in the project and add a section for it to `CHANGELOG.md`.
2. Commit, then tag and push: `git tag -a v0.5.0 -m "Brim 0.5.0" && git push --follow-tags`.
3. The workflow builds and ad-hoc signs Brim, packages a DMG, publishes a GitHub Release with the changelog notes, and updates the cask in [homebrew-brim](https://github.com/ieralyte/homebrew-brim).

To build the same DMG locally, run `scripts/make-dmg.sh`; it lands in `dist/`.

The tap update needs a `TAP_TOKEN` repository secret: a fine-grained personal access token with **Contents: read and write** on `homebrew-brim`. Without it, releases still publish and the tap step is skipped.

## Project layout

```
Brim/
  App/                  Entry point, app delegate, Settings window
  Notch/                The notch panel, its shape, hover logic and state
  Features/NowPlaying/  Now Playing service and views
  Features/FileTray/    File tray service and views
  Features/Battery/     Battery service, alerts and indicator
  LockScreen/           Lock screen card and the window that holds it
  Platform/Private/     The only place private Apple APIs are allowed
  Resources/            Bundled resources (the media adapter's Perl loader)
Vendor/
  MediaRemoteAdapter/   Third-party adapter source, built as an embedded framework
```

## How it works

- A borderless `NSPanel` sits above the menu bar on every Space, including full-screen apps.
- Global `NSEvent` mouse-move monitors detect when the pointer reaches the notch; no Accessibility permission is needed.
- The island is a SwiftUI view whose size and corner radii animate with a spring.
- While closed, the panel ignores the mouse, so clicks pass straight through to the menu bar.
- When a file drag reaches the notch, Brim notices it on the drag pasteboard and opens the island as a drop target.
- The tray stores bookmarks, not copies, so files can move or be renamed and still resolve.
- Battery updates come from IOKit power-source notifications; nothing polls.
- **Lock screen** uses Apple's private SkyLight window server API, following [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow): Brim creates a window-server space at the level macOS uses for lock screen notifications and moves its card into it when the screen locks. Every private call is looked up at runtime, so if macOS removes one, the feature switches off and Settings says so.
- **Now Playing** comes from Apple's private MediaRemote framework. Since macOS 15.4 it only answers Apple-signed processes, so Brim uses [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter): a small framework loaded by the system's `/usr/bin/perl`, which streams updates back as JSON. It works with Apple Music, Spotify, Tidal and browser players. If a macOS update breaks it, Settings shows Now Playing as unavailable and the rest of Brim keeps working.

## Contributing

Issues and pull requests are welcome. Please keep private-API code inside `Platform/Private/`, behind a protocol, so a macOS update can only disable a feature, never crash the app.

## Acknowledgements

Inspired by [Canopy](https://getcanopy.pro/). Brim is an independent project, not affiliated with Canopy, and shares none of its code or assets.

The app icon's lettering is set in [Outfit](https://github.com/Outfitio/Outfit-Fonts) (SIL Open Font License, see [`design/OFL-Outfit.txt`](design/OFL-Outfit.txt)); the icon sources are in [`design/`](design).

Brim bundles [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) by Jonas van den Berg and contributors (BSD 3-Clause, see [`Vendor/MediaRemoteAdapter/LICENSE`](Vendor/MediaRemoteAdapter/LICENSE)), vendored from commit `0e82bf1`. The lock screen technique is adapted from [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) by Lakr Aream (MIT License).

## Licence

[MIT](LICENSE) © 2026 Tan Wei Jian. Third-party code keeps its own licence (see Acknowledgements).
