#!/bin/bash
set -e
WT=$(git rev-parse --show-toplevel)
MAIN=$(git worktree list | head -1 | cut -d' ' -f1)
CONF="${1:-$HOME/.claude/memory/worktree-deps.conf}"
NAME=$(basename "$MAIN")

[ "$WT" = "$MAIN" ] && { echo "SAME_PATH"; exit 1; }
[ -f "$CONF" ] || { echo "NO_CONF"; exit 2; }

section=""; found=0
while IFS= read -r line; do
  case "$line" in
    \[*\])
      section="${line#[}"; section="${section%]}"
      ;;
    link\ *|copy\ *)
      [ "$section" = "$NAME" ] || continue
      found=1
      action="${line%% *}"; rel="${line#* }"
      src="$MAIN/$rel"; dst="$WT/$rel"
      mkdir -p "$(dirname "$dst")"
      if [ "$action" = "link" ]; then
        [ -e "$dst" ] || ln -s "$src" "$dst"
      else
        [ -e "$dst" ] || cp "$src" "$dst"
      fi
      ;;
  esac
done < "$CONF"

[ "$found" = 1 ] || { echo "UNKNOWN_PROJECT:$NAME"; exit 3; }
echo "DONE:$NAME"
