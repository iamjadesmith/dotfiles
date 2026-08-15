# Nix Configuration

This directory contains the shared Nix flake for NixOS hosts and macOS nix-darwin hosts.

## Layout

- `flake.nix`: single flake entrypoint for NixOS and Darwin.
- `flake.lock`: shared lockfile for all Nix and Darwin systems.
- `hosts/<hostname>/`: host-specific NixOS configuration, hardware configuration, and disko layout.
- `hosts/darwin/configuration.nix`: shared macOS nix-darwin system configuration.
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
- `mini`: nix-darwin configuration for the Mac mini.
- `joejadmbp`: nix-darwin configuration for the MacBook Pro.

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

Switch a macOS host:

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#mini
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#joejadmbp
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

## Self-hosted LiveSync On Mjolnir

Mjolnir runs CouchDB natively and the official Self-hosted LiveSync CLI daemon in Podman. CouchDB listens only on `127.0.0.1:5984`; Nginx provides `https://livesync.joejad.com` to the configured LAN, WireGuard, Tailscale, and private IPv6 ranges. Requests forwarded by Cloudflare Tunnel are rejected.

Persistent data and units:

- CouchDB data: `/var/lib/couchdb`
- CLI database and settings: `/var/lib/livesync-cli/database`
- Materialised vault: `/var/lib/livesync-cli/vault`
- User-facing vault path: `~/obsidian`, a symlink to `/var/lib/livesync-cli/vault`
- Services: `couchdb.service` and `podman-livesync-cli.service`
- CouchDB database: `obsidian`
- CouchDB client: `livesync`, with its password in the `couchdb_livesync_user_password` SOPS key

The administrator credential is used only by the local provisioning service. Clients are restricted to the `obsidian` database, and Nginx does not expose CouchDB's server-management APIs. The CLI service is skipped safely until `/var/lib/livesync-cli/database/.livesync/settings.json` exists and reports `isConfigured: true`. Before each daemon start, the service atomically enables `liveSync` in that settings file so a Setup URI cannot leave the headless mirror idle after its initial scan. The `jade` user is a member of the `livesync` group and can access the materialised vault through `~/obsidian` after starting a new login session. The CLI does not materialise hidden paths such as `.obsidian`.

For an existing Obsidian device that is the source of truth:

1. Back up the vault and disable every other synchronisation tool for that vault.
2. Rebuild mjolnir. Retrieve the generated database-user password from the root-only runtime secret and store it in a password manager:

```bash
sudo cat /run/secrets/couchdb_livesync_user_password
```

3. Explicitly reset the remote database so the authoritative upload cannot merge with data from an earlier attempt. This permanently deletes the `obsidian` database, quarantines any previous CLI database and mirror under `/var/lib/livesync-cli/reset-backup.*`, and recreates empty CLI directories:

```bash
sudo livesync-couchdb-reset --confirm-delete-obsidian
```

4. Connect the Self-hosted LiveSync plug-in manually to `https://livesync.joejad.com` with user `livesync`, the SOPS-managed password, and database `obsidian`. Skip the optional server-requirements check because Nix manages those settings and the client deliberately has no server-administrator access.
5. Enable end-to-end encryption, choose the existing device as authoritative, and initialise or overwrite the verified-empty remote database. Keep Obsidian open until the initial upload finishes.
6. Create a fresh Setup URI with `Self-hosted LiveSync: Copy settings as a new Setup URI`. Do not reuse an initial provisioning URI. Keep the URI and its passphrase separate.
7. Initialise the CLI settings, paste the fresh Setup URI when `read` waits for input, and enter its passphrase at the CLI prompt:

```bash
sudo systemctl stop podman-livesync-cli.service
sudo livesync-cli init-settings /data/.livesync/settings.json
read -rs setup_uri
sudo livesync-cli setup "$setup_uri"
unset setup_uri
sudo systemctl start podman-livesync-cli.service
sudo journalctl -u podman-livesync-cli.service -f
```

Stop `podman-livesync-cli.service` before any later one-off `sudo livesync-cli ...` command. One-off commands and the Borg job share a lock so that neither can copy or open the CLI database while the other is using it. CouchDB and the full CLI state are included in mjolnir's weekly Borg job; the job stops both services for a consistent cold backup and starts them afterward. Synchronisation is not a substitute for a tested backup restore.

## Custom Modules

The `modules/dotfiles/` directory contains small modules that remove repeated NixOS host boilerplate.

- `server.nix`: shared server defaults such as bootloader, locale, SSH, Nix settings, and common system behavior.
- `mdns.nix`: shared Avahi hostname publication and `.local` resolution for NixOS hosts.
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

Install Nix, clone the repository, then run the command matching the host:

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#mini
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#joejadmbp
```

Homebrew packages, casks, and App Store apps are managed by nix-darwin in `hosts/darwin/configuration.nix`.
