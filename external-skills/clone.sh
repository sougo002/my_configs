#!/bin/bash
# repos.txt に列挙されたgit repositoryを ghq get でcloneする。
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOS_FILE="$SCRIPT_DIR/repos.txt"

if ! command -v ghq &>/dev/null; then
  echo "[WARN] ghq is not installed (brew bundle を実行してください)" >&2
  exit 1
fi

while IFS= read -r url; do
  [[ -z "$url" || "$url" == \#* ]] && continue
  ghq get "$url"
done <"$REPOS_FILE"
