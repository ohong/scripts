// Toggles Chrome's tab sidebar by walking the accessibility tree of Chrome's
// main window and pressing the "Expand tabs" / "Collapse tabs" button.
//
// Build via ./build.sh (produces bin/toggle-chrome-sidebar).

import AppKit
import ApplicationServices

let chromeBundleID = "com.google.Chrome"
let toggleTitles: Set<String> = ["Expand tabs", "Collapse tabs"]
let maxSearchDepth = 14

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func stringAttribute(_ element: AXUIElement, _ name: CFString) -> String {
    var value: CFTypeRef?
    AXUIElementCopyAttributeValue(element, name, &value)
    return value as? String ?? ""
}

func windowAttribute(_ element: AXUIElement, _ name: CFString) -> AXUIElement? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name, &value) == .success,
          let v = value
    else { return nil }
    return unsafeDowncast(v, to: AXUIElement.self)
}

func findToggleButton(in element: AXUIElement, depth: Int = 0) -> AXUIElement? {
    if depth > maxSearchDepth { return nil }

    let role = stringAttribute(element, kAXRoleAttribute as CFString)
    if role == (kAXButtonRole as String) {
        let title = stringAttribute(element, kAXTitleAttribute as CFString)
        let desc = stringAttribute(element, kAXDescriptionAttribute as CFString)
        if toggleTitles.contains(title) || toggleTitles.contains(desc) {
            return element
        }
    }

    var childrenRef: CFTypeRef?
    AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)
    guard let children = childrenRef as? [AXUIElement] else { return nil }

    for child in children {
        if let found = findToggleButton(in: child, depth: depth + 1) {
            return found
        }
    }
    return nil
}

guard let chrome = NSRunningApplication
    .runningApplications(withBundleIdentifier: chromeBundleID)
    .first(where: { $0.activationPolicy == .regular })
else {
    fail("Chrome is not running")
}

let app = AXUIElementCreateApplication(chrome.processIdentifier)

// Build a candidate window list. Chrome's accessibility tree varies by state:
// when active, kAXWindows[0] is sometimes a stub with no descendants and only
// kAXMainWindow exposes the real UI; when inactive, kAXWindows can be empty.
// Try main and focused first, then everything else.
var candidates: [AXUIElement] = []
if let main = windowAttribute(app, kAXMainWindowAttribute as CFString) {
    candidates.append(main)
}
if let focused = windowAttribute(app, kAXFocusedWindowAttribute as CFString) {
    candidates.append(focused)
}
var windowsRef: CFTypeRef?
if AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef) == .success,
   let windows = windowsRef as? [AXUIElement] {
    candidates.append(contentsOf: windows)
}

if candidates.isEmpty {
    fail("No Chrome window found")
}

for window in candidates {
    if let button = findToggleButton(in: window) {
        AXUIElementPerformAction(button, kAXPressAction as CFString)
        exit(0)
    }
}

fail("Sidebar toggle button not found — is the tab sidebar enabled?")
