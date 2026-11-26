# scripts
Some scripts I run to automate common computer tasks. Feel free to copy &amp; use!

## Codex token audit

`bin/codex-token-audit` ranks recent Codex sessions by processed tokens and shows
fresh input, cached input, output, turns, and tool-call counts. Use it to find
workflows with excessive context replay or tool round trips without confusing
cached tokens with newly processed context.

```sh
bin/codex-token-audit 20
```

## Hammerspoon

`hammerspoon/init.lua` is the active Hammerspoon config. Install or update it
with:

```sh
cp hammerspoon/init.lua ~/.hammerspoon/init.lua
```

It gives Chrome two app-scoped shortcuts:

- `Cmd+Shift+C` copies the active tab URL and shows a small confirmation toast.
- `Cmd+S` toggles Chrome's vertical tabs sidebar through the Raycast extension
  helper.

The event taps only swallow those shortcuts while Chrome is frontmost, so Arc,
Dia, and other apps keep their own native shortcuts.

## Raycast Extensions

Chrome sidebar toggling is handled by the upstream Raycast extension
[`saqibameen/chrome-sidebar-toggle`](https://github.com/saqibameen/chrome-sidebar-toggle).
The local shell and Swift implementation was removed so the Raycast extension is
the single owner for that behavior.

Installed checkout:

```sh
/Users/ohong/dev/chrome-sidebar-toggle
```

The local Raycast extension was installed from commit
`91ce1ecc72d7a072461ca350431a94bf97035ea1` with:

```sh
npm install
npm run dev
```

Do not assign the Chrome sidebar command a Raycast hotkey if the key should be
free in other apps. Raycast command hotkeys are global, so Hammerspoon owns the
Chrome-only `Cmd+S` binding and calls the compiled Raycast helper directly.
