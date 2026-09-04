#!/bin/bash
# The ~/.claude.json cleanup in uninstall.sh -- handing back the per-piece
# consent that bin/art recorded.
#
# It edits entries rather than removing them, because everything else in one is
# Claude Code's own record of sessions that happened. Most cases below are
# about paths it must not reach: a prefix lookalike such as ~/ArtStuff is the
# one a naive startswith() would eat.
set -uo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
source "$ROOT/tests/lib.sh"

sandbox
trap cleanup EXIT

mkdir -p "$ART_HOME/wind-field" "$ART_HOME/forest"

cat >"$HOME/.claude.json" <<JSON
{
  "numStartups": 7,
  "projects": {
    "$ART_HOME/wind-field": {
      "hasTrustDialogAccepted": true,
      "hasClaudeMdExternalIncludesApproved": true,
      "hasClaudeMdExternalIncludesWarningShown": true,
      "lastCost": 0.42,
      "allowedTools": ["Bash"]
    },
    "$ART_HOME/forest": {
      "hasTrustDialogAccepted": true,
      "hasClaudeMdExternalIncludesApproved": false,
      "hasClaudeMdExternalIncludesWarningShown": true
    },
    "$ART_HOME/deep/nested": { "hasTrustDialogAccepted": true },
    "$ART_HOME": { "hasTrustDialogAccepted": true },
    "$T/home/Work": { "hasTrustDialogAccepted": true },
    "$T/home/ArtStuff/x": { "hasTrustDialogAccepted": true }
  }
}
JSON
chmod 600 "$HOME/.claude.json"

printf '\n\033[1muninstall.sh\033[0m  (trust handed back)\n\n'

out=$(bash "$ROOT/uninstall.sh" 2>&1)

check "it reports what it cleared" \
  "$(grep -c 'claude.json (trust for 2' <<<"$out")" "1"

check "consent flags go, the rest of the entry stays" \
  "$(piece_entry "$ART_HOME/wind-field")" '{"lastCost":0.42,"allowedTools":["Bash"]}'
check "a piece whose include was declined is cleared too" \
  "$(piece_entry "$ART_HOME/forest")" '{}'

check "a nested directory is not a piece" \
  "$(piece_entry "$ART_HOME/deep/nested")" '{"hasTrustDialogAccepted":true}'
check "ART_HOME itself is untouched" \
  "$(piece_entry "$ART_HOME")" '{"hasTrustDialogAccepted":true}'
check "an unrelated project is untouched" \
  "$(piece_entry "$T/home/Work")" '{"hasTrustDialogAccepted":true}'
check "a prefix lookalike (~/ArtStuff) is untouched" \
  "$(piece_entry "$T/home/ArtStuff/x")" '{"hasTrustDialogAccepted":true}'

check "top-level keys survive" "$(jq -r .numStartups "$HOME/.claude.json")" "7"
check "the result is still valid JSON" \
  "$(jq -e . "$HOME/.claude.json" >/dev/null 2>&1 && echo yes || echo no)" "yes"
check "file mode is preserved" "$(stat -c %a "$HOME/.claude.json")" "600"
check "no temp files are left behind" "$(strays)" "0"

before=$(md5sum <"$HOME/.claude.json")
bash "$ROOT/uninstall.sh" >/dev/null 2>&1
check "a second uninstall rewrites nothing" \
  "$(md5sum <"$HOME/.claude.json")" "$before"

echo 'not json' >"$HOME/.claude.json"
bash "$ROOT/uninstall.sh" >/dev/null 2>&1
check "a corrupt config is left as found" "$(cat "$HOME/.claude.json")" "not json"
check "and no temp file survives the failure" "$(strays)" "0"

rm -f "$HOME/.claude.json"
bash "$ROOT/uninstall.sh" >/dev/null 2>&1
check "a missing config is not recreated" \
  "$([[ -e $HOME/.claude.json ]] && echo created || echo absent)" "absent"

summary
