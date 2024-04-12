# Neovim

This repository holds the base Neovim configuration of Dreams of Code, for use in videos as a starting point in tutorials

## Installation


### Installing Latest Version of Neovim on Debian

Download from Source

```bash
curl -O -L https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
```

Install the App Image

```bash
sudo chmod u+x nvim.appimage
sudo mv nvim.appimage /usr/bin/nvim
```

### Backup

if you have an existing neovim configuration, first back this up and clean out your neovim cache.

```bash
mv ~/.config/nvim ~/.config/nvim-backup
rm -rf ~/.local/share/nvim
```

or remove it entirely

```bash
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
```

remove it on Windows

```pwsh
rm -rf $ENV:USERPROFILE\AppData\Local\nvim
```
### Install


To install this configuration on Linux & macOS, run the following command:

```bash
git clone git@github.com:iamjadesmith/neovim.git ~/.config/nvim
```

To do it on Windows:

```pwsh
git clone git@github.com:iamjadesmith/neovim.git $ENV:USERPROFILE\AppData\Local\nvim
```

Then, open up neovim in order to download and install the base configuration packages.

## Modifying

### Custom Plugins

All custom plugins shown in videos should be added to the `lua/custom/plugins.lua` file.
