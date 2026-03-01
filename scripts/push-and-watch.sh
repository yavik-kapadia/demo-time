#!/usr/bin/env bash
# Push to origin main, then watch the Release workflow until it completes.
set -e
cd "$(git rev-parse --show-toplevel)"
REPO="${REPO:-yavik-kapadia/demo-time}"

echo "Pushing to origin main..."
git push origin main

echo ""
echo "Watching latest Release run..."
sleep 3
RUN_ID=$(gh run list --repo "$REPO" --workflow "Release" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch "$RUN_ID" --repo "$REPO" --exit-status
