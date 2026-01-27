# ==============================================================================
# Environment Variables (loaded for all shells including non-interactive)
# ==============================================================================

# Cargo/Rust
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# PATH
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# mise (for non-interactive shells)
if [[ -f ~/.local/bin/mise ]]; then
  eval "$(~/.local/bin/mise env)"
fi

# Tokens (API keys, etc.)
[[ -f ~/.tokens ]] && source ~/.tokens
