#!/usr/bin/env zsh

# ==============================================================================
# Shell Options
# ==============================================================================
setopt share_history
setopt inc_append_history
setopt hist_ignore_dups

# ==============================================================================
# Shell Variables
# ==============================================================================
export DISABLE_TELEMETRY=1 # for modern web guidance

# ==============================================================================
# Aliases
# ==============================================================================

# zsh
alias resource=". ~/.zshrc"
alias code-rc="code ~/.zshrc"

# ls (requires: eza)
alias ls='eza --icons=auto'
alias ll='eza --icons=auto -lah'
alias llt='eza --icons=auto -lah -T -L2'

# cd
alias cdhome='cd ~'

# docker
alias dc="docker compose"
alias up="docker compose up -d && docker compose logs -f"
alias down="docker compose down"
alias watch="docker compose watch"
alias logs="docker compose logs"

# misc
alias beep="afplay /System/Library/Sounds/Ping.aiff"
alias ccode="claude"

# jidで絞り込んでクリップボードにコピーする関数
jidcp() {
  if [ -p /dev/stdin ]; then
    # パイプで受け取った場合 (例: cat log.json | jidcp)
    cat - | jid | pbcopy
  else
    # 引数でファイル名を渡した場合 (例: jidcp history.json)
    cat "$1" | jid | pbcopy
  fi
  echo "Copied to clipboard!"
}

# ==============================================================================
# PATH & Tools (interactive shell)
# ==============================================================================
[[ -f ~/.local/bin/mise ]] && eval "$(~/.local/bin/mise activate zsh)"

# ==============================================================================
# Terminal Title
# ==============================================================================
precmd() {
  print -Pn "\e]0;📁 %1~\a"
}
preexec() {
  print -Pn "\e]0;⚡️ $1 (%1~)\a"
}

# ==============================================================================
# ghq
# ==============================================================================

# `gv` opens fzf; typing there filters in real time.
gv() {
  if (( $# > 0 )) && [[ "$1" == "-q" || "$1" == "--filter" ]]; then
    command gv "$@"
    return
  fi

  local bin preview_script dest
  bin=$(whence -p gv) || return 1
  preview_script="${${bin:A}:h}/gv-fzf-preview"

  dest=$(ghq list -p | fzf \
    --height 80% \
    --layout reverse \
    --border \
    --prompt 'ghq> ' \
    --preview "$preview_script {}" \
    --preview-window 'right:60%:wrap' \
    --bind 'ctrl-o:execute-silent(bash -c "cd \"{}\" && gh browse" >/dev/null 2>&1)')

  [[ -n "$dest" ]] && cd "$dest"
}

# ==============================================================================
# Git Functions
# ==============================================================================

# Copy GitHub commit URL to clipboard
function com-url() {
  local com
  if [ -z "$1" ]; then
    com=$(git rev-parse --short HEAD)
  fi
  url=$(gh browse "$com" -n)
  echo "$url" | pbcopy
  echo "Copied: $url"
}

# Interactive branch switcher with fzf
function git-switch-graph() {
  local default_branch
  default_branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||')

  if [[ -z "$default_branch" ]]; then
    return 1
  fi

  local current
  current=$(git rev-parse --abbrev-ref HEAD)

  local -a entries
  local -a seen
  local line author date m b

  while IFS= read -r line; do
    author=$(echo "$line" | cut -d'|' -f2)
    date=$(echo "$line" | cut -d'|' -f3)
    m=$(echo "$line" | cut -d'|' -f4)
    b=$(echo "$m" | sed -n 's/.*from \([^ ]*\).*/\1/p')

    if [[ -n "$b" ]] && ! (( ${seen[(Ie)$b]} )) && [[ "$b" != "$current" ]]; then
      seen+=("$b")
      entries+=("$b|$author|$date")
    fi
  done < <(git reflog --format='%gD|%an|%ad|%gs' --date=short | grep 'checkout: moving from')

  if [[ ${#entries[@]} -eq 0 ]]; then
    return 1
  fi

  local picked
  picked=$(printf "%s\n" "${entries[@]}" \
    | column -ts'|' \
    | fzf --ansi --exact --preview='git log --oneline --graph --decorate --color=always -50 {+1}' \
    | awk '{print $1}')

  if [[ -z "$picked" ]]; then
    return 0
  fi

  local target
  target=$(echo "$picked" | cut -d'|' -f1)

  git switch "$target"
}

# ==============================================================================
# Git Prompt & Completion
# ==============================================================================
source ~/.zsh/git-prompt.sh

fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
autoload -Uz compinit && compinit

GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM=auto

# ==============================================================================
# Prompt
# ==============================================================================
setopt PROMPT_SUBST
PS1='%F{green}%n@%m%f: %F{cyan}%~%f %F{red}$(__git_ps1 "(%s)")%f
\$ '

# ==============================================================================
# Local Overrides (machine-specific settings)
# ==============================================================================
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
