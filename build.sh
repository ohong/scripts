#!/bin/bash
# Compile native binaries for Raycast script commands.

set -euo pipefail
cd "$(dirname "$0")"
mkdir -p bin

swiftc -O toggle-chrome-sidebar.swift -o bin/toggle-chrome-sidebar
echo "✓ bin/toggle-chrome-sidebar"
