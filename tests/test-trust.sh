#!/bin/bash
# trust_dir() / trust_claude() in bin/art -- the code that records per-piece
# consent in ~/.claude.json so `art make` does not open on a modal dialog.
#
# What matters here is that it stays narrow. It writes to a config file that
# belongs to another tool, so every case below is about something it must NOT
# touch.
set -uo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
source "$ROOT/tests/lib.sh"

sandbox
trap cleanup EXIT
stub_agent claude

mkdir -p "$ART_HOME/wind-field" "$ART_HOME/not-a-piece" "$T/elsewhere"
echo '{"title":"Wind Field"}' >"$ART_HOME/wind-field/art.json"   # a real piece
: >"$ART_HOME/not-a-piece/README.md"                             # no art.json
echo '{}' >"$T/elsewhere/art.json"                               # outside ART_HOME

cat >"$HOME/.claude.json" <<'JSON'
{
  "numStartups": 7,
  "projects": {
    "/somewhere/else": { "hasTrustDialogAccepted": true, "allowedTools": ["Bash"] }
  }
}
JSON
chmod 600 "$HOME/.claude.json"

# shellcheck disable=SC1090  -- `help` so sourcing does not run a command
source "$ROOT/bin/art" help >/dev/null 2>&1

printf '\n\033[1mtrust_dir\033[0m  (bin/art)\n\n'

trust_dir "$ART_HOME/wind-field"
check "a scaffolded piece gets both consents" \
  "$(jq -r --arg d "$ART_HOME/wind-field" \
      '[.projects[$d].hasTrustDialogAccepted,
        .projects[$d].hasClaudeMdExternalIncludesApproved,
        .projects[$d].hasClaudeMdExternalIncludesWarningShown] | @csv' \
      "$HOME/.claude.json")" \
  "true,true,true"

check "an unrelated project is untouched" \
  "$(piece_entry /somewhere/else)" '{"hasTrustDialogAccepted":true,"allowedTools":["Bash"]}'
check "top-level keys survive" "$(jq -r .numStartups "$HOME/.claude.json")" "7"
check "file mode is preserved" "$(stat -c %a "$HOME/.claude.json")" "600"

trust_dir "$ART_HOME/not-a-piece"
check "a directory with no art.json is skipped" \
  "$(piece_entry "$ART_HOME/not-a-piece")" '"ABSENT"'

trust_dir "$T/elsewhere"
check "a piece outside ART_HOME is skipped" \
  "$(piece_entry "$T/elsewhere")" '"ABSENT"'

mkdir -p "$ART_HOME/opt-out"; echo '{}' >"$ART_HOME/opt-out/art.json"
ART_NO_TRUST=1 trust_dir "$ART_HOME/opt-out"
check "ART_NO_TRUST=1 keeps the prompt" \
  "$(piece_entry "$ART_HOME/opt-out")" '"ABSENT"'

stub_agent codex
mkdir -p "$ART_HOME/other-agent"; echo '{}' >"$ART_HOME/other-agent/art.json"
trust_dir "$ART_HOME/other-agent"
check "an agent with no known trust format is a no-op" \
  "$(piece_entry "$ART_HOME/other-agent")" '"ABSENT"'
stub_agent claude

before=$(md5sum <"$HOME/.claude.json")
trust_dir "$ART_HOME/wind-field"
check "re-trusting an already-trusted piece rewrites nothing" \
  "$(md5sum <"$HOME/.claude.json")" "$before"

check "no temp files are left behind" "$(strays)" "0"

echo 'not json at all' >"$HOME/.claude.json"
trust_dir "$ART_HOME/wind-field" 2>/dev/null
check "a corrupt config is left as found, not destroyed" \
  "$(cat "$HOME/.claude.json")" "not json at all"
check "and no temp file survives the failure" "$(strays)" "0"

rm -f "$HOME/.claude.json"
trust_dir "$ART_HOME/wind-field"
check "a missing config is a silent no-op" \
  "$([[ -e $HOME/.claude.json ]] && echo created || echo absent)" "absent"

summary
