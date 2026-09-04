#!/bin/bash
# Remove Art Computer.
#
# Your artwork is never touched. This removes what install.sh created, plus the
# per-piece trust `art` recorded in ~/.claude.json while you used it.
# --purge additionally removes ~/Art/lib and the agent instruction files
# (still not your sketches).

set -uo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ART_HOME="${ART_HOME:-$HOME/Art}"
ART_HOME="${ART_HOME%/}"
PURGE=0
[[ ${1:-} == --purge ]] && PURGE=1

gone() { printf '  \033[31m-\033[0m %s\n' "$*"; }
kept() { printf '  \033[90m·\033[0m %s\n' "$*"; }

MARK_BEGIN='-- >>> art-computer >>>'
MARK_END='-- <<< art-computer <<<'

printf '\n\033[1mArt Computer\033[0m  uninstalling\n\n'

command -v art >/dev/null && art serve --stop >/dev/null 2>&1

for l in "$HOME/.local/bin/art" \
         "$HOME/.agents/skills/art-computer" \
         "$HOME/.claude/skills/art-computer" \
         "$HOME/.codex/skills/art-computer" \
         "$HOME/.config/omarchy/hooks/theme-set.d/10-art-palette"; do
  [[ -L $l ]] && { rm -f "$l"; gone "${l/#$HOME/\~}"; }
done

for f in "$HOME/.config/hypr/art-computer.lua" \
         "$HOME/.local/share/applications/art-computer.desktop"; do
  [[ -f $f ]] && { rm -f "$f"; gone "${f/#$HOME/\~}"; }
done

B="$HOME/.config/hypr/bindings.lua"
if [[ -f $B ]] && grep -qF -- "$MARK_BEGIN" "$B"; then
  cp "$B" "$B.bak.$(date +%s)"
  sed -i "\|$MARK_BEGIN|,\|$MARK_END|d" "$B"
  gone "~/.config/hypr/bindings.lua (require line; backup made)"
fi

M="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
if [[ -f $M ]] && grep -q '"art.make"' "$M"; then
  cp "$M" "$M.bak.$(date +%s)"
  sed -i '/^  "art\(\.\(make\|mine\|learn\|explore\)\)\?":/d' "$M"
  gone "omarchy menu entries (backup made)"
fi

# The consent `art` recorded for each piece, handed back. Only the three flags
# it set are cleared -- everything else in those entries is Claude Code's own
# record of sessions that really happened, and not ours to delete. Entries are
# matched by path, so this is scoped to direct children of ART_HOME and cannot
# reach another project.
CFG="$HOME/.claude.json"
H=$(realpath -e "$ART_HOME" 2>/dev/null || printf '%s' "$ART_HOME")
PIECE='def piece($h): startswith($h + "/") and ((ltrimstr($h + "/")) | index("/") | not);'
if [[ -f $CFG ]] && command -v jq >/dev/null; then
  n=$(jq --arg h "$H" "$PIECE"'
        [ (.projects // {}) | to_entries[]
          | select((.key | piece($h))
                   and (.value.hasTrustDialogAccepted == true
                        or .value.hasClaudeMdExternalIncludesApproved == true)) ]
        | length' "$CFG" 2>/dev/null)
  if [[ $n =~ ^[0-9]+$ ]] && ((n > 0)); then
    # Temp file beside the original so the rename is atomic, as in bin/art.
    tmp=$(mktemp "$CFG.art.XXXXXX")
    if jq --arg h "$H" "$PIECE"'
          .projects |= with_entries(
            if (.key | piece($h))
            then .value |= del(.hasTrustDialogAccepted,
                               .hasClaudeMdExternalIncludesApproved,
                               .hasClaudeMdExternalIncludesWarningShown)
            else . end)' "$CFG" >"$tmp" 2>/dev/null && [[ -s $tmp ]]; then
      chmod --reference="$CFG" "$tmp" 2>/dev/null
      mv -f "$tmp" "$CFG"
      gone "~/.claude.json (trust for $n piece(s); nothing else in the file changed)"
    else
      rm -f "$tmp"
      kept "~/.claude.json could not be rewritten — trust left as it is"
    fi
  fi
fi

if ((PURGE)); then
  for f in "$ART_HOME/lib/p5.min.js" "$ART_HOME/lib/p5.LICENSE.txt" \
           "$ART_HOME/lib/palette.json" "$ART_HOME/lib/palette.js" \
           "$ART_HOME/AGENTS.md" "$ART_HOME/CLAUDE.md"; do
    [[ -e $f || -L $f ]] && { rm -f "$f"; gone "${f/#$HOME/\~}"; }
  done
  rmdir "$ART_HOME/lib" 2>/dev/null && gone "${ART_HOME/#$HOME/\~}/lib"
fi

command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1

printf '\n'
kept "your artwork is untouched in ${ART_HOME/#$HOME/\~}"
printf '\n'
