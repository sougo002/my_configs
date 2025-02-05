#!/bin/bash

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
