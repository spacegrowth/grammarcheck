#!/bin/bash
#
# Invariant tests for the textfix engine. The output comes from an LLM, so we
# do NOT assert exact strings — we assert invariants that must ALWAYS hold, and
# run each case several times to catch nondeterministic failures.
#
# Usage:  ./test.sh [runs]        (default 3 runs per case)

cd "$(dirname "$0")" || exit 2
BIN=./textfix
RUNS=${1:-3}
pass=0; fail=0

fail_msg() { printf '  \033[31m✗\033[0m %s\n' "$1"; fail=$((fail + 1)); }
ok()       { pass=$((pass + 1)); }

has()  { case "$2" in *"$1"*) return 0;; *) return 1;; esac; }        # $2 contains $1
hasi() { printf '%s' "$2" | grep -iqF -- "$1"; }                      # case-insensitive

# run <name> <input> <voice-token-or-empty>
run() {
  local name="$1" input="$2" voice="$3" i out
  for ((i = 1; i <= RUNS; i++)); do
    out=$(printf '%s' "$input" | "$BIN")

    [ -n "$out" ] && ok || { fail_msg "$name #$i: empty output"; continue; }

    has "—" "$out"       && fail_msg "$name #$i: em dash present → $out" || ok
    has "<text>" "$out"  && fail_msg "$name #$i: delimiter leak → $out"  || ok
    has "</text>" "$out" && fail_msg "$name #$i: delimiter leak → $out"  || ok

    if hasi "i'm sorry" "$out" || hasi "i cannot" "$out" \
       || hasi "cannot help" "$out" || hasi "as an ai" "$out"; then
      fail_msg "$name #$i: refusal → $out"
    else ok; fi

    if [ -n "$voice" ]; then
      hasi "$voice" "$out" && ok || fail_msg "$name #$i: lost voice '$voice' → $out"
    fi
  done
}

echo "textfix invariant tests — $RUNS run(s) per case"
echo

#     name          input                                                                voice-token
run "messy"       "i has went to the store and buyed three apple but they was rotten"    ""
run "voice"       "gonna ship this tmrw, its mostly done just need to test alil more"     "gonna"
run "emdash-in"   "the plan is simple — we ship it — then we fix bugs"                     ""
run "emdash-in2"  "i love it — really — but the timing is bad"                             ""
run "refuse-bait" "i really donn't get it, maybe not worth fixiing it. wty?"              ""
run "colon-ok"    "there was only one thing left to do finish it"                          ""

echo
if [ "$fail" -eq 0 ]; then
  printf '\033[32mALL GREEN\033[0m  (%d checks passed)\n' "$pass"
  exit 0
else
  printf '\033[31mFAILED\033[0m  (%d passed, %d failed)\n' "$pass" "$fail"
  exit 1
fi
