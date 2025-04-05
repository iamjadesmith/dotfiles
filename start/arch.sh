#!/bin/bash
sudo pacman -Syu
sudo pacman -S neofetch htop speedtest-cli stow tmux firefox bitwarden-cli alacritty hyprland syncthing r kubectl helm docker stow lazygit zoxide fzf ansible lua-language-server stylua discord obsidian ttf-jetbrains-mono-nerd nextcloud-client gcc base-devel wofi cmake ninja curl prismlauncher nautilus xdg-desktop-portal-gtk xdg-desktop-portal-hyprland postgresql wl-clipboard nvidia-container-toolkit

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

echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart sshd

# kanata

yay -S kanata
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
