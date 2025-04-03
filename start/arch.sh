#!/bin/bash
sudo pacman -Syu
sudo pacman -S neofetch htop speedtest-cli stow tmux firefox bitwarden-cli alacritty hyprland syncthing r kubectl helm docker stow lazygit zoxide fzf ansible lua-language-server stylua discord obsidian ttf-jetbrains-mono-nerd nextcloud-client gcc base-devel wofi cmake ninja curl

cd ~/.dotfiles
stow .
touch ~/.hushlogin

git clone https://aur.archlinux.org/yay.git ~/yay
cd ~/yay
makepkg -si

mkdir ~/.config/tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

cd ~
curl -s https://ohmyposh.dev/install.sh | bash -s
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh

echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart sshd
