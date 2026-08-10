# scripts
Some scripts I run to automate common computer tasks. Feel free to copy &amp; use!

## Hammerspoon

`hammerspoon/init.lua` is the active Hammerspoon config. Install or update it
with:

```sh
cp hammerspoon/init.lua ~/.hammerspoon/init.lua
```

It gives Chrome two app-scoped shortcuts:

- `Cmd+Shift+C` copies the active tab URL and shows a small confirmation toast.
- `Cmd+S` expands or collapses Chrome's vertical tabs sidebar without changing
  Chrome's tab position setting.

The event taps only swallow those shortcuts while Chrome is frontmost, so Arc,
Dia, and other apps keep their own native shortcuts.

## Chrome Sidebar

Chrome sidebar toggling is handled directly by Hammerspoon with macOS
accessibility scripting. On machines with the Raycast `toggle-chrome-sidebar`
helper installed, Hammerspoon calls that helper; otherwise it falls back to
pressing Chrome's `Expand tabs` / `Collapse tabs` button itself. It never invokes
`Show tabs vertically`, because that command changes Chrome's `Tab position`
setting between vertical and horizontal.
