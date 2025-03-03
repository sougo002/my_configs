#!/bin/bash

# git prompt
if [ ! -d ~/.zsh ]; then
  mkdir ~/.zsh
fi
if [ ! -f ~/.zsh/git-prompt.sh ]; then
  curl -o ~/.zsh/git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi
if [ ! -f ~/.zsh/git-completion.bash ]; then
  curl -o ~/.zsh/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
fi
if [ ! -f ~/.zsh/_git ]; then
  curl -o ~/.zsh/_git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
fi

# Install tools managed by homebrew
{{ if eq .chezmoi.os "darwin" }}
if ! type xcode-select > /dev/null 2>&1; then
  xcode-select --install
fi
# install brew
if ! type brew > /dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew bundle --global
{{ end }}

# Install mise dependencies
if type mise > /dev/null 2>&1; then
  mise install
fi

# Install deno
if type deno > /dev/null 2>&1; then
  curl -fsSL https://deno.land/install.sh | sh
fi