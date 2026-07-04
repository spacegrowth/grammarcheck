#!/bin/bash
#
# SwiftBar plugin: fix the grammar/spelling of the currently selected text in
# place, using an on-device language model. It keeps your wording and voice and
# only nudges wording when something is clearly wrong.
#
# Trigger it two ways: click "Fix" in the menu, or press the global hotkey.
# On trigger: save the clipboard, copy the selection, run it through the engine,
# paste the result back, then restore the clipboard.

BIN="$HOME/development/grammarbar/textfix"
CFG="$HOME/.config/textfix"
action="$1"   # ""  -> draw menu ;  fix -> transform ;  edit -> rules file

copy_selection() { osascript -e 'tell application "System Events" to keystroke "c" using command down'; }
paste_result()   { osascript -e 'tell application "System Events" to keystroke "v" using command down'; }

# Soft sound feedback: a tick when the model starts, a pop when text is pasted.
# To silence: set VOL=0, or delete the two afplay lines below.
VOL=0.3
sound_start() { afplay -v "$VOL" /System/Library/Sounds/Tink.aiff >/dev/null 2>&1 & }
sound_done()  { afplay -v "$VOL" /System/Library/Sounds/Pop.aiff  >/dev/null 2>&1 & }

# Visual "working" cue: while the model runs, show a small black dot next to the
# icon. We flip a flag file and ask SwiftBar to re-render this plugin; the
# menu-draw path below shows the dot whenever the flag is present.
refresh_icon() { open -g "swiftbar://refreshplugin?name=$(basename "$0")" 2>/dev/null; }
set_busy()   { mkdir -p "$CFG"; : > "$CFG/.busy"; refresh_icon; }
clear_busy() { rm -f "$CFG/.busy"; refresh_icon; }

# ---- fix the current selection ----
if [ "$action" = "fix" ]; then
  original=$(pbpaste)                 # 1. remember what was on the clipboard
  copy_selection
  sleep 0.15                          # 2. let the copy land on the clipboard
  selection=$(pbpaste)
  if [ -n "$selection" ]; then
    sound_start                       #    tick: model is running
    set_busy                          #    black dot: model is running
    result=$(printf '%s' "$selection" | "$BIN")
    clear_busy
    if [ -n "$result" ]; then
      printf '%s' "$result" | pbcopy  # 3. put result on clipboard and paste it
      paste_result
      sleep 0.15                      #    let the paste consume the clipboard
      sound_done                      #    pop: fixed text is in place
    fi
  fi
  printf '%s' "$original" | pbcopy    # 4. restore the user's clipboard
  exit 0
fi

# ---- open the rules file (seed via the binary so it always exists) ----
if [ "$action" = "edit" ]; then
  "$BIN" seed
  open -e "$CFG/rules.txt"
  exit 0
fi

# ---- draw the menu ----
# Icon rendered inline as an SF Symbol with an outline/fill pair: outline when
# idle, filled (and green) while working. Both variants are the same width, so
# the icon never shifts; the glyph itself just fills in.
if [ -f "$CFG/.busy" ]; then
  echo ":text.bubble.fill: | size=14 color=#3fb950"
else
  echo ":text.bubble: | size=14"
fi
echo "---"
echo 'Fix | shortcut=CMD+` bash='"$0"' param1=fix terminal=false refresh=false'
echo "---"
echo "Edit rules… | bash=$0 param1=edit terminal=false refresh=false"
echo "---"
echo "Select text, then press ⌘\` or click Fix."
