#!/bin/bash
# Install Art Computer.
#
# Everything this touches is listed below and removed by ./uninstall.sh.
# Nothing under /usr/share/omarchy is written. Your artwork is never modified.

set -uo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ART_HOME="${ART_HOME:-$HOME/Art}"
WITH_MENU=0

while (($#)); do
  case "$1" in
    --menu) WITH_MENU=1; shift ;;
    --art-home) ART_HOME="${2:?--art-home needs a directory}"; shift 2 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

ok()   { printf '  \033[32m+\033[0m %s\n' "$*"; }
skip() { printf '  \033[90m·\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }

MARK_BEGIN='-- >>> art-computer >>>'
MARK_END='-- <<< art-computer <<<'

printf '\n\033[1mArt Computer\033[0m  installing from %s\n\n' "$ROOT"

# 1. the CLI ------------------------------------------------------------------
mkdir -p "$HOME/.local/bin"
if [[ -e $HOME/.local/bin/art && ! -L $HOME/.local/bin/art ]]; then
  warn "~/.local/bin/art exists and is not a symlink — leaving it alone"
else
  ln -sfn "$ROOT/bin/art" "$HOME/.local/bin/art"; ok "~/.local/bin/art"
fi

# 2. the sketchbook -----------------------------------------------------------
mkdir -p "$ART_HOME/lib"; ok "$ART_HOME"

# 3. p5.js (never overwrite — the user may have swapped versions deliberately)
if [[ -f $ART_HOME/lib/p5.min.js ]]; then
  skip "$ART_HOME/lib/p5.min.js (already there)"
else
  cp "$ROOT/vendor/p5-1.11.13/p5.min.js"  "$ART_HOME/lib/p5.min.js"
  cp "$ROOT/vendor/p5-1.11.13/LICENSE.txt" "$ART_HOME/lib/p5.LICENSE.txt"
  ok "$ART_HOME/lib/p5.min.js (p5.js 1.11.13, LGPL-2.1)"
fi

# 4. agent instructions (never overwrite — agents and users edit these) -------
if [[ -e $ART_HOME/AGENTS.md ]]; then skip "$ART_HOME/AGENTS.md (already there)"
else cp "$ROOT/share/AGENTS.md" "$ART_HOME/AGENTS.md"; ok "$ART_HOME/AGENTS.md"; fi

# CLAUDE.md is the same document under the name Claude Code looks for. A
# symlink, not a "@AGENTS.md" import line: agents run inside an artwork
# subdirectory, so that import resolves outside their working directory and
# Claude Code stops to ask about external files on every single launch.
if [[ -e $ART_HOME/CLAUDE.md || -L $ART_HOME/CLAUDE.md ]]; then
  skip "$ART_HOME/CLAUDE.md (already there)"
else
  ln -s AGENTS.md "$ART_HOME/CLAUDE.md"; ok "$ART_HOME/CLAUDE.md -> AGENTS.md"
fi

# 5. palette from the current theme -------------------------------------------
ART_HOME="$ART_HOME" "$ROOT/lib/art-palette" "$ART_HOME" 2>/dev/null && ok "$ART_HOME/lib/palette.json"

# 6. agent skill, into every agent that keeps skills here ---------------------
for d in "$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.codex/skills"; do
  if [[ -d $d ]]; then
    ln -sfn "$ROOT/skills/art-computer" "$d/art-computer"; ok "${d/#$HOME/\~}/art-computer"
  fi
done

# 7. Hyprland: our own file, plus one require() line --------------------------
if [[ -d $HOME/.config/hypr ]]; then
  cp "$ROOT/share/hypr/art-computer.lua" "$HOME/.config/hypr/art-computer.lua"
  ok "~/.config/hypr/art-computer.lua  (SUPER+A, SUPER+ALT+A)"

  B="$HOME/.config/hypr/bindings.lua"
  if [[ -f $B ]] && grep -qF -- "$MARK_BEGIN" "$B"; then
    skip "~/.config/hypr/bindings.lua (already wired)"
  elif [[ -f $B ]]; then
    cp "$B" "$B.bak.$(date +%s)"
    printf '\n%s\nrequire("hypr.art-computer")\n%s\n' "$MARK_BEGIN" "$MARK_END" >>"$B"
    ok "~/.config/hypr/bindings.lua (appended require; backup made)"
  fi
  command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 && ok "hyprland reloaded"
fi

# 8. keep the palette current when the theme changes --------------------------
H="$HOME/.config/omarchy/hooks/theme-set.d"
if [[ -d $H ]]; then
  ln -sfn "$ROOT/share/hooks/10-art-palette" "$H/10-art-palette"
  ok "~/.config/omarchy/hooks/theme-set.d/10-art-palette"
fi

# 9. launcher entry -----------------------------------------------------------
if [[ -d $HOME/.local/share/applications ]]; then
  cp "$ROOT/share/art-computer.desktop" "$HOME/.local/share/applications/art-computer.desktop"
  ok "~/.local/share/applications/art-computer.desktop"
fi

# 10. omarchy menu — opt in, because that file is JSONC the user owns ---------
M="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
if ((WITH_MENU)) && [[ -f $M ]]; then
  if grep -q '"art.make"' "$M"; then
    skip "omarchy menu (already there)"
  else
    cp "$M" "$M.bak.$(date +%s)"
    # Entries belong inside the top-level object; insert before its last brace.
    python3 - "$M" "$ROOT/share/menu/art-computer.jsonc" <<'PY'
import sys
menu, snippet = sys.argv[1], sys.argv[2]
s = open(menu).read()
add = open(snippet).read()
i = s.rstrip().rfind('}')
body = s[:i].rstrip()
if body.rstrip().endswith(('{', ',')) or not body.strip().endswith(('}', ']', '"')):
    pass
else:
    body += ','
open(menu, 'w').write(body + '\n' + add + s[i:])
PY
    ok "omarchy menu entries (backup made)"
  fi
elif [[ -f $M ]]; then
  skip "omarchy menu — rerun with --menu, or paste share/menu/art-computer.jsonc"
fi

# ----------------------------------------------------------------------------
printf '\n\033[1mready.\033[0m\n\n'
printf '  art make "a field of grass where every blade follows invisible wind"\n'
printf '  art home          (or SUPER + A)\n\n'
