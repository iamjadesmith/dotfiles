#!/bin/bash

xcode-select --install

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

brew install neovim tmux bitwarden-cli syncthing r kubernetes-cli stow helm yt-dlp lazygit zoxide fzf ansible oh-my-posh lua-language-server stylua ffmpeg ripgrep
brew install --cask alacritty ente-auth discord raycast obsidian font-jetbrains-mono-nerd-font nextcloud
brew install --cask nikitabobko/tap/aerospace

curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
rustup component add rust-analyzer

cd ~/.dotfiles
stow .
ln -s ~/.dotfiles/.config/alacritty/alacritty_mac.toml ~/.config/alacritty/alacritty.toml

mkdir ~/.config/tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

brew services start syncthing

defaults write com.apple.dock autohide-delay -float 0;
killall Dock
