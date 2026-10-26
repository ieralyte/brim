# Brim

A free, open-source Dynamic Island for MacBooks. Brim turns the notch into a live strip for media, files and battery status, and puts Now Playing on your lock screen.

> **Status: v0.1, early development.** The notch shell works: hover the notch and it expands. Features arrive milestone by milestone; see [the roadmap](docs/ROADMAP.md).

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
  App/      Entry point, app delegate, Settings window
  Notch/    The notch panel, its shape, hover logic and state
```

Later milestones add `Features/` (Now Playing, File Tray, Battery), `LockScreen/`, and `Platform/Private/` (the only place private Apple APIs are allowed).

## How it works

- A borderless `NSPanel` sits above the menu bar on every Space, including full-screen apps.
- Global `NSEvent` mouse-move monitors detect when the pointer reaches the notch; no Accessibility permission is needed.
- The island is a SwiftUI view whose size and corner radii animate with a spring.
- While closed, the panel ignores the mouse, so clicks pass straight through to the menu bar.

## Contributing

Issues and pull requests are welcome. Please keep private-API code inside `Platform/Private/`, behind a protocol, so a macOS update can only disable a feature, never crash the app.

## Acknowledgements

Inspired by [Canopy](https://getcanopy.pro/). Brim is an independent project, not affiliated with Canopy, and shares none of its code or assets.

## Licence

[MIT](LICENSE) © 2026 Tan Wei Jian
