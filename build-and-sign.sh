#!/bin/bash
# Build and sign Demo Time. Requires Xcode (not just Command Line Tools).
# One-time: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

set -e
cd "$(dirname "$0")"

if ! xcodebuild -version &>/dev/null; then
  echo "xcodebuild not found. Switch to Xcode with:"
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

echo "Building and signing Demo Time (Release)..."
xcodebuild -scheme "Demo Time" -configuration Release build

echo ""
echo "Build succeeded. App:"
find ~/Library/Developer/Xcode/DerivedData -name "Demo Time.app" -type d 2>/dev/null | head -1
