#!/bin/bash

xcode-select --install

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

brew install neovim tmux bitwarden-cli syncthing r kubernetes-cli stow helm yt-dlp lazygit zoxide fzf ansible oh-my-posh lua-language-server stylua
brew install --cask alacritty ente-auth discord raycast obsidian font-jetbrains-mono-nerd-font

curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh

cd ~/.dotfiles
stow .

mkdir ~/.tmux
mkdir ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
