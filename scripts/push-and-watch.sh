#!/usr/bin/env bash
# Push to origin main, then watch the Release workflow until it completes.
set -e
cd "$(git rev-parse --show-toplevel)"

echo "Pushing to origin main..."
git push origin main

echo ""
echo "Watching latest workflow run (Release)..."
gh run watch --exit-status
