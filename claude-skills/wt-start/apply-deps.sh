#!/bin/bash
set -e

# Usage: apply-deps.sh [worktree_path] [conf_path]
WT_ARG="${1:-}"
CONF_ARG="${2:-}"

if [ -n "$WT_ARG" ] && [ -d "$WT_ARG" ]; then
  WT=$(cd "$WT_ARG" && pwd)
  MAIN=$(git -C "$WT" worktree list | head -1 | cut -d' ' -f1)
else
  WT=$(git rev-parse --show-toplevel)
  MAIN=$(git worktree list | head -1 | cut -d' ' -f1)
fi

CONF="${CONF_ARG:-$MAIN/.cursor/worktrees.json}"
NAME=$(basename "$MAIN")

if [ "$WT" = "$MAIN" ]; then
  echo "SAME_PATH"
  exit 0
fi

[ -f "$CONF" ] || { echo "NO_CONF"; exit 2; }

ROOT_WORKTREE_PATH="$MAIN" python3 - "$CONF" "$WT" <<'PY'
import json
import os
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
worktree_path = Path(sys.argv[2])

try:
    config = json.loads(config_path.read_text())
except (OSError, json.JSONDecodeError) as error:
    print(f"INVALID_CONF:{error}", file=sys.stderr)
    raise SystemExit(3)

setup = config.get("setup-worktree-unix", config.get("setup-worktree"))
if setup is None:
    print("NO_SETUP", file=sys.stderr)
    raise SystemExit(4)

env = os.environ.copy()
if isinstance(setup, list):
    if not all(isinstance(command, str) for command in setup):
        print("INVALID_CONF:setup commands must be strings", file=sys.stderr)
        raise SystemExit(3)
    for command in setup:
        subprocess.run(
            command,
            cwd=worktree_path,
            env=env,
            shell=True,
            executable="/bin/bash",
            check=True,
        )
elif isinstance(setup, str):
    script_path = worktree_path / ".cursor" / setup
    subprocess.run(["/bin/bash", script_path], cwd=worktree_path, env=env, check=True)
else:
    print("INVALID_CONF:setup must be an array or script path", file=sys.stderr)
    raise SystemExit(3)
PY

echo "DONE:$NAME"
