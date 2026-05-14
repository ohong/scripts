#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copy Chrome URL
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔗
# @raycast.packageName Browser Utils

# Documentation:
# @raycast.description Copies the URL of the active tab in Chrome. Does nothing if Chrome isn't the frontmost app.
# @raycast.author ohong
# @raycast.authorURL https://raycast.com/ohong

tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
end tell

if frontApp is not "Google Chrome" then return

tell application "Google Chrome"
    if (count of windows) > 0 then
        set the clipboard to URL of active tab of front window
    end if
end tell
