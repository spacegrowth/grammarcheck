# textfix

Fix the grammar and spelling of the selected text anywhere on macOS, using
Apple's **on-device** language model. Select text in any app, press a hotkey,
and it's corrected in place. Nothing leaves the machine.

- **On-device only.** Uses `SystemLanguageModel.default` (Apple Foundation
  Models). It never uses Private Cloud Compute.
- **Keeps your voice.** Fixes mechanics (spelling, grammar, punctuation) and
  only nudges wording when something is clearly wrong. No rewriting or restyling.
- **No em dashes.** Enforced deterministically after the model runs.

## Pieces

| File | What it is |
|------|------------|
| `main.swift` | The engine. Reads text on stdin, corrects it, prints to stdout. |
| `textfix.1d.sh` | A [SwiftBar](https://github.com/swiftbar/SwiftBar) plugin: menu-bar icon + global hotkey that drives the engine over the current selection. |
| `test.sh` | Invariant tests (no em dashes, no delimiter leaks, no refusals, voice preserved). |

## Requirements

- macOS 26+ on Apple Silicon, with Apple Intelligence enabled.
- Swift 6 toolchain (`swiftc`).
- [SwiftBar](https://swiftbar.app) for the menu-bar/hotkey front end.

## Build

```sh
swiftc -O main.swift -o textfix
```

Quick check:

```sh
echo "i has went to the store and buyed three apple" | ./textfix
# -> I have gone to the store and bought three apples.
```

Run the tests (each case is checked several times because the output is from an LLM):

```sh
./test.sh 5
```

## Install the front end

1. Build `textfix` (above). The plugin expects it at
   `~/development/grammarbar/textfix` — adjust the `BIN=` line in
   `textfix.1d.sh` if you put it elsewhere.
2. Copy the plugin into your SwiftBar plugin folder and make it executable:

   ```sh
   cp textfix.1d.sh ~/.swiftbar/
   chmod +x ~/.swiftbar/textfix.1d.sh
   ```

3. Grant SwiftBar **Accessibility** (System Settings → Privacy & Security →
   Accessibility) so it can copy/paste on your behalf.

Now select text in any app and press **⌘`** (or click **Fix** in the menu).

## Customizing the rules

The correction rules live in `~/.config/textfix/rules.txt`, seeded with the
default on first run. Edit it (or use **Edit rules…** in the menu) and the next
run picks it up. Delete the file to reset to the default.
