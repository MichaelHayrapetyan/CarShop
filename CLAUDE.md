# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

iOS SwiftUI app (iPhone, iOS 26.4+, Xcode 26). Single target `CarShop`, no third-party dependencies, no test target. Currently a fresh scaffold.

## Build / Run

```
open CarShop.xcodeproj
xcodebuild build -project CarShop.xcodeproj -scheme CarShop -configuration Debug
xcodebuild -list -project CarShop.xcodeproj
```

## Architecture

- `CarShop/CarShopApp.swift` — `@main` entry point with a `WindowGroup` hosting `ContentView`.
- `CarShop/ContentView.swift` — root view.
- `CarShop/Assets.xcassets/` — app icons and colors.
- The Xcode project uses file-system-synchronized groups: new Swift files added under `CarShop/` are picked up automatically; no `project.pbxproj` edits required.
