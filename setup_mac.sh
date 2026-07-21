#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# ==============================================================================
# Helper Functions
# ==============================================================================

info() {
  echo "[INFO] $1"
}

warn() {
  echo "[WARN] $1"
}

error() {
  echo "[ERROR] $1" >&2
  exit 1
}

# Create symlink with backup
link_file() {
  local src="$1"
  local dest="$2"

  if [[ -L "$dest" ]]; then
    # Already a symlink - compare with realpath for normalization
    if [[ "$(realpath "$dest")" == "$(realpath "$src")" ]]; then
      info "Already linked: $dest"
      return 0
    else
      warn "Removing old symlink: $dest"
      rm "$dest"
    fi
  elif [[ -e "$dest" ]]; then
    # Backup existing file
    mkdir -p "$BACKUP_DIR"
    info "Backing up: $dest -> $BACKUP_DIR/"
    mv "$dest" "$BACKUP_DIR/"
  fi

  ln -s "$src" "$dest"
  info "Linked: $dest -> $src"
}

# ==============================================================================
# Dotfiles Symlinks
# ==============================================================================

setup_dotfiles() {
  info "Setting up dotfiles symlinks..."

  for file in "$DOTFILES_DIR"/.*; do
    filename=$(basename "$file")
    [[ "$filename" == "." || "$filename" == ".." ]] && continue

    if [[ "$filename" == ".config" ]]; then
      # .config配下はサブディレクトリ単位でXDG_CONFIG_HOMEにリンク
      mkdir -p "$CONFIG_HOME"
      for subdir in "$file"/*/; do
        [[ -d "$subdir" ]] || continue
        link_file "$subdir" "$CONFIG_HOME/$(basename "$subdir")"
      done
    else
      # その他のdotfilesはHOMEに直接リンク
      link_file "$file" "$HOME/$filename"
    fi
  done
}

# ==============================================================================
# Git Prompt Setup
# ==============================================================================

setup_git_prompt() {
  info "Setting up git prompt..."

  if [[ ! -d ~/.zsh ]]; then
    mkdir -p ~/.zsh
  fi

  if [[ ! -f ~/.zsh/git-prompt.sh ]]; then
    curl -sS -o ~/.zsh/git-prompt.sh \
      https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
    info "Downloaded git-prompt.sh"
  fi

  if [[ ! -f ~/.zsh/git-completion.bash ]]; then
    curl -sS -o ~/.zsh/git-completion.bash \
      https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
    info "Downloaded git-completion.bash"
  fi

  if [[ ! -f ~/.zsh/_git ]]; then
    curl -sS -o ~/.zsh/_git \
      https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
    info "Downloaded git-completion.zsh"
  fi
}

# ==============================================================================
# macOS Setup
# ==============================================================================

setup_macos() {
  if [[ "$(uname)" != "Darwin" ]]; then
    return 0
  fi

  info "Setting up macOS tools..."

  # Xcode Command Line Tools
  if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
  fi

  # Homebrew
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Install from Brewfile
  if [[ -f "$SCRIPT_DIR/Brewfile" ]]; then
    info "Installing Homebrew packages..."
    brew bundle --file="$SCRIPT_DIR/Brewfile" || warn "Some Homebrew packages failed to install"
  fi
}

# ==============================================================================
# Claude Code Skills Setup
# git管理外のスキルを残すため、dotfilesとは別でスキル単位でリンク
# ==============================================================================

setup_claude_skills() {
  info "Setting up Claude Code skills..."

  local claude_skills_dir="$SCRIPT_DIR/claude-skills"
  local target_dir="$HOME/.claude/skills"

  if [[ ! -d "$claude_skills_dir" ]]; then
    info "No Claude skills found in repository"
    return 0
  fi

  mkdir -p "$target_dir"

  for skill in "$claude_skills_dir"/*/; do
    [[ -d "$skill" ]] || continue
    local skill_name
    skill_name=$(basename "$skill")
    link_file "$skill" "$target_dir/$skill_name"
  done
}

# ==============================================================================
# External Skills
# 依存repositoryの一覧とスキルのリンク先は external-skills/ 配下のスクリプトで管理する
# （repos.txt / skills.txt / clone.sh / link.sh）
# ==============================================================================

setup_external_skills() {
  local external_skills_dir="$SCRIPT_DIR/external-skills"

  if [[ ! -d "$external_skills_dir" ]]; then
    info "No external-skills directory found"
    return 0
  fi

  info "Cloning external skill repositories..."
  bash "$external_skills_dir/clone.sh"

  info "Linking external skills..."
  bash "$external_skills_dir/link.sh"
}

# ==============================================================================
# Standalone Scripts Setup
# scripts/<name>/<name> を ~/.local/bin/<name> にリンクしてPATHから呼べるようにする
# ==============================================================================

setup_scripts() {
  info "Setting up standalone scripts..."

  local scripts_dir="$SCRIPT_DIR/scripts"
  local target_dir="$HOME/.local/bin"

  if [[ ! -d "$scripts_dir" ]]; then
    info "No scripts directory found"
    return 0
  fi

  mkdir -p "$target_dir"

  for tool_dir in "$scripts_dir"/*/; do
    [[ -d "$tool_dir" ]] || continue
    local tool_name
    tool_name=$(basename "$tool_dir")
    local tool_path="$tool_dir$tool_name"
    if [[ -x "$tool_path" ]]; then
      link_file "$tool_path" "$target_dir/$tool_name"
    fi
  done
}

# ==============================================================================
# Tools Setup
# ==============================================================================

setup_tools() {
  # mise
  if command -v mise &>/dev/null; then
    info "Installing mise dependencies..."
    mise install
  fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
  info "Starting setup..."
  info "Script directory: $SCRIPT_DIR"
  info "Dotfiles directory: $DOTFILES_DIR"

  setup_dotfiles
  setup_git_prompt
  setup_macos
  setup_claude_skills
  setup_external_skills
  setup_scripts
  setup_tools

  info "Setup complete!"

  if [[ -d "$BACKUP_DIR" ]]; then
    info "Backups saved to: $BACKUP_DIR"
  fi
}

main "$@"
