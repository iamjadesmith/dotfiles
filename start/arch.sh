#!/bin/bash
sudo pacman -Syu
sudo pacman -S neofetch htop speedtest-cli stow tmux firefox bitwarden-cli alacritty hyprland syncthing r kubectl helm docker docker-compose stow lazygit zoxide fzf ansible lua-language-server stylua discord obsidian ttf-jetbrains-mono-nerd nextcloud-client gcc base-devel wofi cmake ninja curl prismlauncher nautilus xdg-desktop-portal-gtk xdg-desktop-portal-hyprland postgresql wl-clipboard waybar pipewire-pulse less bluez bluez-utils bind ripgrep mandoc

cd ~/.dotfiles
stow .
touch ~/.hushlogin
ln -s ~/.dotfiles/.config/alacritty/alacritty_linux.toml ~/.config/alacritty/alacritty.toml

git clone https://aur.archlinux.org/yay.git ~/yay
cd ~/yay
makepkg -si

mkdir ~/.config/tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

cd ~
curl -s https://ohmyposh.dev/install.sh | bash -s
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
rustup component add rust-analyzer

echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart sshd

# kanata

yay -S kanata zen-browser-bin
sudo groupadd uinput
sudo usermod -aG input joejad
sudo usermod -aG uinput joejad

text='KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"'
echo "$text" | sudo tee -a /etc/udev/rules.d/99-input.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
ls -l /dev/uinput

systemctl --user daemon-reload
systemctl --user enable kanata.service
systemctl --user start kanata.service
systemctl --user status kanata.service

# docker
sudo groupadd docker
sudo usermod -aG docker $USER

sudo systemctl start docker.service
sudo systemctl start containerd.service
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

systemctl --user enable syncthing.service
systemctl --user start syncthing.service
systemctl --user status syncthing.service

# open-webui
curl -LsSf https://astral.sh/uv/install.sh | sh

systemctl --user enable open-webui.service
systemctl --user start open-webui.service
systemctl --user status open-webui.service
