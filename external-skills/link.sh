#!/bin/bash
# skills.txt に列挙されたパスを ~/.claude/skills にシンボリックリンクする。
# repo_nameは ghq root配下の github.com/<owner>/<repo> に解決する。
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_FILE="$SCRIPT_DIR/skills.txt"
TARGET_DIR="$HOME/.claude/skills"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

if ! command -v ghq &>/dev/null; then
  echo "[WARN] ghq is not installed (brew bundle を実行してください)" >&2
  exit 1
fi

GHQ_ROOT="$(ghq root)"

info() {
  echo "[INFO] $1"
}

warn() {
  echo "[WARN] $1"
}

link_file() {
  local src="$1"
  local dest="$2"

  if [[ -L "$dest" ]]; then
    if [[ "$(realpath "$dest")" == "$(realpath "$src")" ]]; then
      info "Already linked: $dest"
      return 0
    else
      warn "Removing old symlink: $dest"
      rm "$dest"
    fi
  elif [[ -e "$dest" ]]; then
    mkdir -p "$BACKUP_DIR"
    info "Backing up: $dest -> $BACKUP_DIR/"
    mv "$dest" "$BACKUP_DIR/"
  fi

  ln -s "$src" "$dest"
  info "Linked: $dest -> $src"
}

mkdir -p "$TARGET_DIR"

while IFS='|' read -r skill_name repo_name rel_path; do
  [[ -z "$skill_name" || "$skill_name" == \#* ]] && continue

  src="$GHQ_ROOT/github.com/$repo_name/$rel_path"

  if [[ ! -d "$src" ]]; then
    warn "Skipping $skill_name: source not found ($src)"
    continue
  fi

  link_file "$src" "$TARGET_DIR/$skill_name"
done <"$SKILLS_FILE"
