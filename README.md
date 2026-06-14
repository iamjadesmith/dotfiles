# Dotfiles

Personal dotfiles and system configuration for NixOS, macOS, Home Manager, shell tooling, tmux, and Neovim.

## Layout

- `.config/`: application configuration managed as dotfiles.
- `nix/`: consolidated NixOS and nix-darwin flake.
- `scripts/`: helper scripts used by shell aliases and system jobs.
- `start/`: bootstrap scripts for non-Nix setup flows.

## Basic Dotfile Setup

Clone the repository:

```bash
git clone git@github.com:iamjadesmith/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Use GNU Stow for non-Nix dotfile symlinks when needed:

```bash
stow .
```

## NixOS And macOS

NixOS and macOS are managed from the consolidated flake in `nix/`.

See `nix/README.md` for host layout, rebuild commands, package conventions, and install notes.

Common commands:

```bash
sudo nixos-rebuild switch --flake ~/.dotfiles/nix#<hostname>
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#mac
```

Home Manager is managed through the system flakes, not standalone Home Manager commands.

## Reference

[Dreams of Autonomy dotfiles video](https://www.youtube.com/watch?v=y6XCebnB9gs)
