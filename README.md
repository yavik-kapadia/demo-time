# Demo Time

A lightweight macOS app for live camera demos. Select any camera or capture card, rotate the feed (0/90/180/270), crop the edges, and go fullscreen — perfect for presenting mobile app demos, hardware prototypes, or anything else on screen.

## Features

- Camera and capture card selection
- Rotation (0, 90, 180, 270 degrees)
- Crop (adjustable top, bottom, left, right)
- Fullscreen mode
- Signed and notarized for macOS

## Install

Download the latest `DemoTime-notarized.zip` from [Releases](https://github.com/yavik-kapadia/demo-time/releases), unzip, and move **Demo Time.app** to Applications.

## Build from source

```bash
xcodebuild -project "Demo Time.xcodeproj" -target "Demo Time" -configuration Release clean build
```

Requires Xcode and macOS 14+.
