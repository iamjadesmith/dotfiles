# Neovim

## Backup

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

## Install


To install this configuration on Linux & macOS, run the following command:

```bash
git clone git@github.com:iamjadesmith/neovim.git ~/.config/nvim
```

To do it on Windows:

```pwsh
git clone git@github.com:iamjadesmith/neovim.git $ENV:USERPROFILE\AppData\Local\nvim
```
