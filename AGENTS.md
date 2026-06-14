# AGENTS.md - Development Guidelines for Dotfiles Repository

This repository contains personal dotfiles, NixOS configurations, nix-darwin configuration, Home Manager modules, shell scripts, and Neovim configuration.

## Repository Structure

- `nix/flake.nix` is the single flake for NixOS and Darwin.
- `nix/hosts/<hostname>/` contains host-specific NixOS config.
- `nix/hosts/darwin/configuration.nix` contains macOS nix-darwin config.
- `nix/home/home.nix` is the shared Home Manager base.
- `nix/home/home-server.nix`, `nix/home/home-desktop.nix`, and `nix/home/home-darwin.nix` are Home Manager entrypoints.
- `nix/modules/common-packages.nix` contains shared package groups.
- `nix/modules/dotfiles/` contains small custom NixOS modules for repeated host patterns.
- `nix/modules/profiles/` contains optional Linux desktop/profile modules and should be preserved even if currently unused.
- `nix/darwin/` is intentionally removed; use `nix#mac` for Darwin.

## Build, Lint, And Test Commands

Run Nix flake commands from `nix/` unless using an absolute flake path.

Check the consolidated flake:

```bash
nix flake check --accept-flake-config
```

Check the consolidated flake when new files are untracked:

```bash
nix flake check path:. --accept-flake-config
```

Build a NixOS host:

```bash
nixos-rebuild build --flake .#hostname
```

Test a NixOS host:

```bash
nixos-rebuild test --flake .#hostname
```

Switch a NixOS host:

```bash
sudo nixos-rebuild switch --flake ~/.dotfiles/nix#hostname
```

Switch the Darwin host:

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#mac
```

Update flake inputs:

```bash
nix flake update
```

Format touched Nix files:

```bash
nixfmt path/to/file.nix
```

Lint shell scripts:

```bash
shellcheck scripts/*
shellcheck start/*.sh
```

Syntax-check shell scripts:

```bash
bash -n scripts/script_name
bash -n start/arch.sh
```

Lint Lua files:

```bash
luacheck .config/nvim/lua/
```

Format Lua files:

```bash
stylua --check .config/nvim/lua/
stylua .config/nvim/lua/
```

Check repository status:

```bash
git status --short
```

Run pre-commit checks if configured:

```bash
pre-commit run --all-files
```

## Nix Conventions

- Use 2-space indentation in Nix files.
- Prefer clear host-local config over custom abstractions when the abstraction saves only a few lines.
- Use readable local helpers such as `domain` and `ssl` for repeated nginx values.
- Keep custom `dotfiles.*` modules small, explainable, and behavior-preserving.
- Add shared Nix packages to `nix/modules/common-packages.nix`.
- Add Darwin Homebrew formulas, casks, and App Store apps to `nix/hosts/darwin/configuration.nix`.
- Use Homebrew for Darwin GUI apps and Darwin packages that are broken in the current Nix channel.
- Do not restore the old `nix/darwin#mac` flake path.
- Do not introduce a second nixpkgs input unless there is a concrete platform-specific need.
- Run `nixfmt` on touched Nix files only.
- Avoid formatting generated `hardware-configuration.nix` files unless intentionally changing them.

## Nix Module Style

Use standard module structure for custom modules:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.example;
in
{
  options.dotfiles.example.enable = lib.mkEnableOption "example defaults";

  config = lib.mkIf cfg.enable {
    # Configuration here
  };
}
```

- Use `lib.mkEnableOption` for module enable flags.
- Use `lib.mkOption` when host config needs a typed input.
- Use `lib.mkIf` for conditional config.
- Use `lib.mkDefault` only when host-specific config should be able to override a default.
- Prefer explicit attrsets over dense chains of `// lib.optionalAttrs` if readability suffers.
- Add short comments for non-obvious module behavior.

## Shell Script Style

- Use `#!/bin/bash` or `#!/bin/zsh`.
- Use `set -euo pipefail` for new Bash scripts unless there is a specific reason not to.
- Quote variable expansions.
- Use `[[ ]]` for string and file tests.
- Use descriptive names for variables and functions.
- Keep scripts executable when they are intended to be run directly.

## Lua Style

- Use 2-space indentation.
- Follow existing Neovim plugin patterns.
- Use `pcall` around optional or failure-prone integrations.
- Keep startup-sensitive config lazy-loaded where practical.

## Security Rules

- Never commit secrets, API keys, passwords, private keys, or tokens.
- Never use `sops` to decrypt secrets in this repository.
- Never inspect decrypted secret contents.
- Prefer encrypted secret stores, environment variables, or OS keychains over plaintext secrets.
- Add sensitive local files to `.gitignore` when needed.
- Preserve least-privilege permissions for sensitive files.

## Git Workflow

- Inspect `git status --short` before and after non-trivial changes.
- Do not revert user changes unless explicitly asked.
- Keep commits focused when the user asks for commits.
- Do not amend commits unless explicitly requested.

## Platform Notes

- NixOS hosts are built from `nix#<hostname>`.
- Darwin is built from `nix#mac`.
- Home Manager is managed through the system flakes, not standalone Home Manager commands.
- Linux desktop profiles are intentionally kept for possible future Linux desktop hosts.
- Test platform-specific service changes on the target platform when possible.

## Documentation

- Keep `nix/README.md` as the detailed Nix operations document.
- Keep root `README.md` short and point to `nix/README.md` for NixOS and Darwin details.
- Update this file when repository structure, build commands, or conventions change.
