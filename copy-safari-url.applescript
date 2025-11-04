#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copy Safari URL
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔗

# Documentation:
# @raycast.description Copies the URL of the current page in Safari to clipboard, like Arc's useful shortcut.
# @raycast.author ohong
# @raycast.authorURL https://raycast.com/ohong

tell application "Safari"
    if (count of windows) > 0 then
        set currentURL to URL of current tab of front window
        set the clipboard to currentURL
    end if
end tell
