#!/bin/bash
# Shared assertions and sandboxing. Sourced by tests/test-*.sh, never run.

PASS=0
FAIL=0

check() {
  local what="$1" got="$2" want="$3"
  if [[ $got == "$want" ]]; then
    printf '  \033[32mok\033[0m    %s\n' "$what"; ((PASS++))
  else
    printf '  \033[31mFAIL\033[0m  %s\n' "$what"
    printf '        want: %s\n        got:  %s\n' "$want" "$got"; ((FAIL++))
  fi
}

summary() {
  printf '\n  %d passed, %d failed\n' "$PASS" "$FAIL"
  [[ $FAIL -eq 0 ]]
}

# A throwaway HOME and sketchbook, plus stubs for everything that would
# otherwise reach the real desktop. These tests write to config files for a
# living, so nothing here is allowed to resolve to the machine running them.
#
# Sets $T (the sandbox root), $HOME and $ART_HOME. Call cleanup() when done.
sandbox() {
  T=$(mktemp -d)
  export HOME="$T/home"
  export ART_HOME="$T/home/Art"
  mkdir -p "$ART_HOME" "$T/bin"

  local stub
  for stub in hyprctl art omarchy-toggle-idle omarchy-launch-webapp; do
    printf '#!/bin/bash\nexit 0\n' >"$T/bin/$stub"
    chmod +x "$T/bin/$stub"
  done

  export PATH="$T/bin:$PATH"
}

# The default agent is read from a file, so a test that needs one writes it
# rather than depending on how the machine happens to be configured.
stub_agent() {
  mkdir -p "$HOME/.config/omarchy/defaults"
  printf '%s\n' "$1" >"$HOME/.config/omarchy/defaults/agent"
  cp "$(command -v omarchy-default-agent)" "$T/bin/" 2>/dev/null || \
    printf '#!/bin/bash\nread -r a <"$HOME/.config/omarchy/defaults/agent" 2>/dev/null && echo "$a"\n' \
      >"$T/bin/omarchy-default-agent"
  chmod +x "$T/bin/omarchy-default-agent"
}

cleanup() { [[ -n ${T:-} ]] && rm -rf "$T"; }

# Every entry of .projects that the trust code could have touched.
piece_entry() { jq -c --arg d "$1" '.projects[$d] // "ABSENT"' "$HOME/.claude.json"; }

strays() { find "$HOME" -maxdepth 1 -name '.claude.json.art.*' | wc -l; }
