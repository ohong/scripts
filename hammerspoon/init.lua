require("hs.ipc")
hs.ipc.cliInstall()
hs.autoLaunch(true)

-- Per-app key handling.
--
-- Chrome gets Arc-style URL copying on Cmd+Shift+C and sidebar toggling on
-- Cmd+S. In every other app the event taps return false, so the keystrokes pass
-- through untouched and native shortcuts keep working.

local chromeBundleID = "com.google.Chrome"
local copyUrlKeyCode = hs.keycodes.map.c
local sidebarToggleKeyCode = hs.keycodes.map.s
chromeCopyUrl = chromeCopyUrl or {}
chromeSidebarToggle = chromeSidebarToggle or {}
chromeSidebarToggle.tasks = chromeSidebarToggle.tasks or {}

local sidebarToggleButtonNames = {
  ["collapse tabs"] = true,
  ["expand tabs"] = true,
}

local sidebarTogglePaths = {
  "/Users/ohong/Library/Application Support/com.raycast-x.macos/extensions/toggle-chrome-sidebar/bin/toggle-chrome-sidebar",
  "/Users/ohong/Library/Application Support/com.raycast.macos/extensions/toggle-chrome-sidebar/bin/toggle-chrome-sidebar",
}

local toastWidth = 220
local toastHeight = 48
local toastMargin = 18
local toastDuration = 1.2

local function frontmostBundleID()
  local front = hs.application.frontmostApplication()
  return front and front:bundleID()
end

local function isCommandShiftOnly(flags)
  return flags.cmd and flags.shift and not flags.alt and not flags.ctrl
end

local function isCommandOnly(flags)
  return flags.cmd and not flags.shift and not flags.alt and not flags.ctrl
end

local function executableSidebarTogglePath()
  for _, path in ipairs(sidebarTogglePaths) do
    if hs.fs.attributes(path, "mode") == "file" then
      return path
    end
  end

  return nil
end

local function removeSidebarToggleTask(task)
  for index = #chromeSidebarToggle.tasks, 1, -1 do
    if chromeSidebarToggle.tasks[index] == task then
      table.remove(chromeSidebarToggle.tasks, index)
      return
    end
  end
end

local function toggleChromeSidebarWithHelper(path)
  local task
  task = hs.task.new(path, function(exitCode, _, stdErr)
    removeSidebarToggleTask(task)
    if exitCode ~= 0 then
      hs.printf("Toggle Chrome sidebar helper failed: %s", stdErr or ("exit " .. tostring(exitCode)))
    end
  end)

  if not task then
    hs.printf("Toggle Chrome sidebar helper failed: could not start helper")
    return false
  end

  table.insert(chromeSidebarToggle.tasks, task)
  return task:start()
end

local function axAttribute(element, attribute)
  local ok, value = pcall(function()
    return element:attributeValue(attribute)
  end)

  if ok then
    return value
  end

  return nil
end

local function isSidebarToggleButton(element)
  if axAttribute(element, "AXRole") ~= "AXButton" then
    return false
  end

  local title = string.lower(axAttribute(element, "AXTitle") or "")
  local description = string.lower(axAttribute(element, "AXDescription") or "")

  return sidebarToggleButtonNames[title] or sidebarToggleButtonNames[description] or false
end

local function findSidebarToggleButton(element, depth)
  if not element or depth > 30 then
    return nil
  end

  if isSidebarToggleButton(element) then
    return element
  end

  for _, child in ipairs(axAttribute(element, "AXChildren") or {}) do
    local found = findSidebarToggleButton(child, depth + 1)
    if found then
      return found
    end
  end

  return nil
end

local function toggleChromeSidebar()
  local helperPath = executableSidebarTogglePath()
  if helperPath then
    return toggleChromeSidebarWithHelper(helperPath)
  end

  local app = hs.application.get(chromeBundleID)
  if not app then
    hs.printf("Toggle Chrome sidebar failed: Chrome is not running")
    return false
  end

  for _, window in ipairs(app:allWindows()) do
    local button = findSidebarToggleButton(hs.axuielement.windowElement(window), 0)
    if button then
      button:performAction("AXPress")
      return true
    end
  end

  hs.printf("Toggle Chrome sidebar failed: Expand/Collapse Tabs button not found")
  return false
end

chromeSidebarToggle.toggle = toggleChromeSidebar

local function copyChromeActiveTabUrl()
  local ok, url = hs.osascript.applescript([[
    tell application "Google Chrome"
      if (count of windows) > 0 then
        return URL of active tab of front window
      end if
    end tell
    return ""
  ]])

  if ok and url ~= "" then
    hs.pasteboard.setContents(url)
    return true
  end

  hs.printf("Copy Chrome URL failed: %s", url)
  return false
end

local function toastFrame()
  local win = hs.window.focusedWindow()
  local frame = win and win:frame() or hs.screen.mainScreen():frame()

  return {
    x = math.max(frame.x + toastMargin, frame.x + frame.w - toastWidth - toastMargin),
    y = frame.y + toastMargin,
    w = toastWidth,
    h = toastHeight,
  }
end

local function showCopiedUrlToast()
  if chromeCopyUrl.toastTimer then
    chromeCopyUrl.toastTimer:stop()
    chromeCopyUrl.toastTimer = nil
  end

  if chromeCopyUrl.toast then
    chromeCopyUrl.toast:delete(0)
    chromeCopyUrl.toast = nil
  end

  local toast = hs.canvas.new(toastFrame())
  toast:level(hs.canvas.windowLevels.overlay)
  toast:behavior({
    hs.canvas.windowBehaviors.canJoinAllSpaces,
    hs.canvas.windowBehaviors.fullScreenAuxiliary,
    hs.canvas.windowBehaviors.transient,
  })
  toast:clickActivating(false)

  toast:appendElements(
    {
      type = "rectangle",
      action = "fill",
      frame = {x = 0, y = 0, w = toastWidth, h = toastHeight},
      roundedRectRadii = {xRadius = 14, yRadius = 14},
      fillColor = {red = 0.86, green = 0.80, blue = 1.0, alpha = 0.96},
      withShadow = true,
      shadow = {
        blurRadius = 16,
        color = {white = 0, alpha = 0.25},
        offset = {w = 0, h = 4},
      },
    },
    {
      type = "text",
      text = "Copied Current URL",
      frame = {x = 18, y = 12, w = 154, h = 24},
      textSize = 16,
      textColor = {white = 0, alpha = 1},
    },
    {
      type = "rectangle",
      action = "fill",
      frame = {x = 180, y = 8, w = 32, h = 32},
      roundedRectRadii = {xRadius = 8, yRadius = 8},
      fillColor = {white = 1, alpha = 0.28},
      strokeColor = {white = 0, alpha = 0.18},
      strokeWidth = 1,
    },
    {
      type = "image",
      image = hs.image.imageFromName("NSShareTemplate"),
      frame = {x = 188, y = 15, w = 16, h = 18},
      imageAlpha = 0.95,
    }
  )

  chromeCopyUrl.toast = toast
  toast:show(0.1)

  chromeCopyUrl.toastTimer = hs.timer.doAfter(toastDuration, function()
    if chromeCopyUrl.toast == toast then
      toast:delete(0.2)
      chromeCopyUrl.toast = nil
      chromeCopyUrl.toastTimer = nil
    end
  end)
end

chromeCopyUrl.tap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
  if event:getKeyCode() ~= copyUrlKeyCode then
    return false
  end

  if not isCommandShiftOnly(event:getFlags()) then
    return false
  end

  if frontmostBundleID() ~= chromeBundleID then
    return false
  end

  if copyChromeActiveTabUrl() then
    showCopiedUrlToast()
  end

  return true
end)

chromeCopyUrl.tap:start()

chromeSidebarToggle.tap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
  if event:getKeyCode() ~= sidebarToggleKeyCode then
    return false
  end

  if not isCommandOnly(event:getFlags()) then
    return false
  end

  if frontmostBundleID() ~= chromeBundleID then
    return false
  end

  toggleChromeSidebar()
  return true
end)

chromeSidebarToggle.tap:start()

-- Keep the tap healthy across wake/unlock, where macOS occasionally disables
-- event taps if the system thinks an event handler was slow.
chromeCopyUrl.tapWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function()
  if not chromeCopyUrl.tap:isEnabled() then
    chromeCopyUrl.tap:start()
  end
  if not chromeSidebarToggle.tap:isEnabled() then
    chromeSidebarToggle.tap:start()
  end
  return false
end)

chromeCopyUrl.tapWatcher:start()
