#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Chrome Sidebar
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📑
# @raycast.packageName Chrome Utils

# Documentation:
# @raycast.description Toggles Chrome's vertical tab sidebar by pressing the Expand/Collapse button via the macOS Accessibility API.
# @raycast.author ohong
# @raycast.authorURL https://raycast.com/ohong

set -euo pipefail

BIN="$(cd "$(dirname "$0")" && pwd)/bin/toggle-chrome-sidebar"

if [[ ! -x "$BIN" ]]; then
    echo "Binary not found at $BIN — run ./build.sh first" >&2
    exit 1
fi

exec "$BIN"
