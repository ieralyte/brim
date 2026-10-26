# Brim

A free, open-source Dynamic Island for MacBooks. Brim turns the notch into a live strip for media, files and battery status, and puts Now Playing on your lock screen.

> **Status: v0.3, early development.** See [the roadmap](docs/ROADMAP.md).

## Features

- **Hover to open.** The notch expands into an island and closes as soon as the pointer leaves.
- **Now Playing.** Artwork, title, artist, a scrubber and controls for Apple Music, Spotify, Tidal and browser players. While music plays, the closed island shows the artwork and a live waveform.
- **File tray.** Drag files onto the notch to hold them, then drag them out wherever you need them. Double-click to open; the tray survives restarts.
- **Battery.** A brief charging notice when you plug in, low-battery alerts at 20% and 10%, and the battery level in the open island.

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

## Installing a release

Prebuilt releases are planned for v0.5 (a DMG on GitHub Releases and a Homebrew tap). They will be unsigned, so macOS blocks the first launch once. To allow it, open **System Settings → Privacy & Security** and click **Open Anyway**.

## Project layout

```
Brim/
  App/                  Entry point, app delegate, Settings window
  Notch/                The notch panel, its shape, hover logic and state
  Features/NowPlaying/  Now Playing service and views
  Features/FileTray/    File tray service and views
  Features/Battery/     Battery service, alerts and indicator
  Platform/Private/     The only place private Apple APIs are allowed
  Resources/            Bundled resources (the media adapter's Perl loader)
Vendor/
  MediaRemoteAdapter/   Third-party adapter source, built as an embedded framework
```

Later milestones add `LockScreen/`.

## How it works

- A borderless `NSPanel` sits above the menu bar on every Space, including full-screen apps.
- Global `NSEvent` mouse-move monitors detect when the pointer reaches the notch; no Accessibility permission is needed.
- The island is a SwiftUI view whose size and corner radii animate with a spring.
- While closed, the panel ignores the mouse, so clicks pass straight through to the menu bar.
- When a file drag reaches the notch, Brim notices it on the drag pasteboard and opens the island as a drop target.
- The tray stores bookmarks, not copies, so files can move or be renamed and still resolve.
- Battery updates come from IOKit power-source notifications; nothing polls.
- **Now Playing** comes from Apple's private MediaRemote framework. Since macOS 15.4 it only answers Apple-signed processes, so Brim uses [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter): a small framework loaded by the system's `/usr/bin/perl`, which streams updates back as JSON. It works with Apple Music, Spotify, Tidal and browser players. If a macOS update breaks it, Settings shows Now Playing as unavailable and the rest of Brim keeps working.

## Contributing

Issues and pull requests are welcome. Please keep private-API code inside `Platform/Private/`, behind a protocol, so a macOS update can only disable a feature, never crash the app.

## Acknowledgements

Inspired by [Canopy](https://getcanopy.pro/). Brim is an independent project, not affiliated with Canopy, and shares none of its code or assets.

Brim bundles [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) by Jonas van den Berg and contributors (BSD 3-Clause, see [`Vendor/MediaRemoteAdapter/LICENSE`](Vendor/MediaRemoteAdapter/LICENSE)), vendored from commit `0e82bf1`.

## Licence

[MIT](LICENSE) © 2026 Tan Wei Jian. Third-party code keeps its own licence (see Acknowledgements).
