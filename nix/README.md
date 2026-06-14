# Nix Configuration

This directory contains the shared Nix flake for NixOS hosts and the macOS nix-darwin host.

## Layout

- `flake.nix`: single flake entrypoint for NixOS and Darwin.
- `flake.lock`: shared lockfile for all Nix and Darwin systems.
- `hosts/<hostname>/`: host-specific NixOS configuration, hardware configuration, and disko layout.
- `hosts/darwin/configuration.nix`: macOS nix-darwin system configuration.
- `home/home.nix`: shared Home Manager base.
- `home/home-server.nix`: server Home Manager entrypoint.
- `home/home-desktop.nix`: Linux desktop Home Manager entrypoint.
- `home/home-darwin.nix`: macOS Home Manager entrypoint.
- `modules/common-packages.nix`: shared package groups for Linux, Linux servers, and Darwin.
- `modules/dotfiles/`: small custom modules for repeated NixOS host patterns.
- `modules/profiles/`: optional Linux desktop/profile modules kept for future hosts.

## Hosts

- `joejadserver`: NixOS server.
- `sorserver`: NixOS server.
- `mjolnir`: NixOS server.
- `mac`: nix-darwin configuration for macOS.

## Common Commands

Run these from `nix/` unless the command uses an absolute flake path.

Check all outputs:

```bash
nix flake check --accept-flake-config
```

Check all outputs when new files are not tracked by git yet:

```bash
nix flake check path:. --accept-flake-config
```

Build a NixOS host:

```bash
nixos-rebuild build --flake .#mjolnir
```

Switch a NixOS host:

```bash
sudo nixos-rebuild switch --flake ~/.dotfiles/nix#mjolnir
```

Switch the macOS host:

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

## Packages

Shared Nix packages live in `modules/common-packages.nix`.

- `commonPackages`: packages used on Linux and Darwin.
- `linuxPackages`: Linux-only packages.
- `linuxServerPackages`: Linux server-only packages.
- `darwinPackages`: Darwin-only Nix packages.

Darwin Homebrew packages live in `hosts/darwin/configuration.nix` under `homebrew.brews`, `homebrew.casks`, and `homebrew.masApps`.

Prefer Nix packages for shared command-line tools when they build reliably on each platform. Prefer Homebrew for Darwin GUI apps or Darwin packages that are broken in the current Nix channel.

## Custom Modules

The `modules/dotfiles/` directory contains small modules that remove repeated NixOS host boilerplate.

- `server.nix`: shared server defaults such as bootloader, locale, SSH, Nix settings, and common system behavior.
- `jade.nix`: shared `jade` user setup with host-specific password and SSH key additions.
- `docker.nix`: shared Docker defaults.
- `borg.nix`: shared Borg user, SSH key generation, and backup job defaults.

Keep custom modules small and easy to understand. If a repeated pattern is only a few lines, prefer a local `let` binding in the host file instead of a new abstraction.

## NixOS Installation Notes

These steps are a starting point for installing a new NixOS host with disko. Replace `<hostname>` with the host directory name, such as `mjolnir`.

Copy the host disko config to the installer:

```bash
scp ~/.dotfiles/nix/hosts/<hostname>/disko-config.nix nixos@nixos:/tmp/disko-config.nix
```

Create any files required by the disko config on the installer system.

Run disko:

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /tmp/disko-config.nix
```

Generate the NixOS hardware config without generated filesystem entries:

```bash
sudo nixos-generate-config --no-filesystems --root /mnt
```

Copy the repo Nix config into the target system:

```bash
sudo mkdir -p /mnt/etc/nixos
sudo cp -r ~/.dotfiles/nix/* /mnt/etc/nixos/
```

Move the generated hardware configuration into the matching host directory:

```bash
sudo mv /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hosts/<hostname>/hardware-configuration.nix
```

Set the root password in the target system if needed:

```bash
sudo nixos-enter --root /mnt -c passwd
```

Install NixOS:

```bash
sudo nixos-install --root /mnt --flake /mnt/etc/nixos#<hostname>
sudo reboot now
```

## macOS Bootstrap

Install Nix, clone the repository, then run:

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#mac
```

Homebrew packages, casks, and App Store apps are managed by nix-darwin in `hosts/darwin/configuration.nix`.
