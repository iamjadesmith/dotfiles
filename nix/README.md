# Nix Configuration

This directory contains the shared Nix flake for NixOS hosts and macOS nix-darwin hosts.

## Layout

- `flake.nix`: single flake entrypoint for NixOS and Darwin.
- `flake.lock`: shared lockfile for all Nix and Darwin systems.
- `hosts/<hostname>/`: host-specific NixOS configuration, hardware configuration, and disko layout.
- `hosts/darwin/configuration.nix`: shared macOS nix-darwin system configuration.
- `home/home.nix`: shared Home Manager base.
- `home/home-server.nix`: server Home Manager entrypoint.
- `home/home-desktop.nix`: Home Manager entrypoint for desktop hosts (mjolnir); adds Hyprland to the server base.
- `home/home-darwin.nix`: macOS Home Manager entrypoint.
- `modules/common-packages.nix`: shared package groups for Linux, Linux servers, and Darwin.
- `modules/dotfiles/`: small custom modules for repeated NixOS host patterns.
- `modules/profiles/`: optional Linux desktop/profile modules. mjolnir uses `linux-desktop.nix` and `gaming.nix`; the rest are kept for future hosts.

## Hosts

- `joejadserver`: NixOS server.
- `sorserver`: NixOS server.
- `mjolnir`: NixOS server, with Hyprland and Steam for occasional gaming.
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

Deploy another server from mjolnir; it builds locally, copies the closure over SSH, and
activates with sudo on the target (servers trust `@wheel` in the Nix daemon for this):

```bash
nixos-rebuild switch --flake .#joejadserver --target-host jade@joejadserver.joejad.lan --sudo
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

### OpenCode

OpenCode comes from nixpkgs through `commonPackages` on NixOS and Darwin, so it updates with `nix flake update`. The global configuration lives in `.config/opencode/opencode.json`.

### Shared Agent Skills

Keep shared skills in `.config/opencode/skills/<name>/SKILL.md`. Home Manager links each skill into `~/.claude/skills` for Claude Code and `~/.agents/skills` for Codex; OpenCode reads the source directory directly. Apply the system configuration after adding or removing skill directories. Edits to existing skills are available through the links without a rebuild. Restart Codex if a skill does not appear, and invoke it with `$<name>`.

### Terminal And Light/Dark Themes

Ghostty is the terminal on Darwin (from the Homebrew cask) and the Linux desktop profile; Home Manager writes its config from `nix/home/ghostty.nix`. Ghostty follows the system appearance with Catppuccin Latte for light mode and TokyoNight Night for dark mode, and reports theme changes to programs (DEC mode 2031). On the Linux desktop profile, darkman switches the system between light and dark at sunrise and sunset (coordinates in `nix/home/home-desktop.nix`) and serves that setting through the XDG settings portal; run `darkman toggle` to switch manually.

Neovim does not store a theme. It reads the terminal's background color at startup and on each theme change, then picks `catppuccin-latte` or `tokyonight-night`, so it follows the Mac even over SSH and inside tmux. `:ThemeLight`, `:ThemeDark`, and `:ThemeToggle` override until the next terminal change; `:ThemeReload` asks the terminal again. tmux switches its status bar colors with the `client-light-theme` and `client-dark-theme` hooks, and fzf uses the terminal's ANSI palette. NixOS hosts install Ghostty's terminfo so `TERM=xterm-ghostty` works over SSH.

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

## Personal Apps On Mjolnir

Mjolnir's personal apps (budget, food_log, golf_rust, meals, receipt, running, stock, tally_rust,
workout_rust, yahtzee_rust) are flake inputs in `flake.nix` that track `main` on internal Forgejo,
pinned in `flake.lock`, with `nixpkgs` following ours. `hosts/mjolnir/personal.nix` imports each
app's `nixosModules.default`, which packages the app with its own flake definition.

Update one app, or let the weekly `update-nix-inputs` timer update everything:

```bash
nix flake update budget
```

To add an app, add an input next to the others (with `inputs.nixpkgs.follows = "nixpkgs"`) and its module
import and service config in `personal.nix`.

Inputs are fetched lazily, so only building mjolnir needs Forgejo. If Forgejo is down (for example while
reinstalling joejadserver before restoring `/var/lib/forgejo` from Borg), build from the local clones
instead. The pins are by revision and NAR hash, so the result is identical as long as each clone has the
locked commit:

```bash
sudo nixos-rebuild switch --flake ~/.dotfiles/nix#mjolnir \
  --override-input budget git+file:///home/jade/projects/budget
```

Repeat `--override-input` for each app that is not already in the Nix store.

## Wedding Private Preview On Mjolnir

Mjolnir fetches an explicitly reviewed `wedding-rsvp` revision from internal Forgejo and runs its
project-owned NixOS module. Independently obtain the matching NAR hash through the public HTTPS Forgejo
origin. The wedding pin is a `fetchTree` in `personal.nix` rather than a flake input, so `nix flake update`
never advances it; promote it only after
application and deployment verification. The synthetic
guest preview is `https://wedding.joejad.com`; its separate admin origin is
`https://wedding-admin.joejad.com`. Both nginx virtual hosts use OPNsense Unbound records, allow only the
configured LAN, VPN, Tailscale, and ULA source ranges, disable request logging, and have
per-client request limits. They must remain absent from public DNS and every Cloudflare Tunnel
configuration.

The service uses local peer-authenticated PostgreSQL and the immutable database identity
`183ddd3c-3741-493b-ba69-dde20e55e1c4`. SOPS renders the service environment from
`wedding_preview_form_signing_key`, `wedding_preview_admin_password_hash`, and
`wedding_preview_admin_session_key`. The separate `wedding_preview_backup_authentication_key` file is
available to explicit backup/recovery commands but is not passed to or readable inside the web unit.

Activation creates only the empty database and service wiring. Follow the pinned application's
`docs/private-preview.md` runbook to migrate, initialize the exact identity, import synthetic fixtures,
synchronize RSVP definitions, and explicitly create preview credentials. Nightly PostgreSQL dumps land
under `/var/lib/db_backups/postgres`; the persistent daily `borgbackup-job-wedding-preview` job first
requires a fresh successful PostgreSQL dump, then sends it and the private wedding artifact directories
to the existing off-host mjolnir Borg repository. Use only
the fixed `wedding_preview_restore_verify` database for same-cluster application backup verification;
the PostgreSQL HBA rejects the service role from every other database.

## Gaming On Mjolnir

Mjolnir is still a server first. Hyprland only runs after logging in on the TTY and running `Hyprland`, so idle power is unchanged the rest of the time. `SUPER+ALT+E` exits it.

Run `gaming-mode on` before a game that needs all of the GPU's VRAM, `gaming-mode off` afterward, and `gaming-mode status` to check. It stops Ollama and Speaches (the only GPU users), the media apps and Immich, and Uptime Kuma on mjolnir so they do not send alerts, and pauses the auto-upgrade and Nix cleanup timers. Other apps stay up. A rebuild or reboot brings the stopped units back; run `gaming-mode on` again after a rebuild.

## Uptime Kuma

The main instance runs on mjolnir at `https://uptime.joejad.com` and watches every service, host, and
background job. Monitors live in Kuma's database (`/var/lib/uptime-kuma`, included in mjolnir's Borg job),
not in Nix, so add and edit them in the web UI. Timed jobs report through push monitors set up with
`dotfiles.kumaPush` (see Custom Modules); after creating a push monitor in the UI, write its URL to
`/var/lib/kuma-push/<service name>` on the host that runs the job (`sudo install -m 600 /dev/stdin ...`).

Kuma cannot report its own host going down, so joejadserver runs a second instance at
`http://joejadserver.joejad.lan:3001` (LAN and Tailscale) that pings mjolnir and checks mjolnir's Kuma.
mjolnir's Kuma checks the joejadserver instance in turn. Both alert through the same Discord notification.

## Custom Modules

The `modules/dotfiles/` directory contains small modules that remove repeated NixOS host boilerplate.

- `server.nix`: shared server defaults such as bootloader, locale, SSH, Nix settings, and common system behavior. `dotfiles.server.networkd.enable` swaps NetworkManager for systemd-networkd; each host still declares its own static `10-lan` network.
- `mdns.nix`: shared Avahi hostname publication and `.local` resolution for NixOS hosts.
- `jade.nix`: shared `jade` user setup with host-specific password and SSH key additions.
- `docker.nix`: shared Docker defaults.
- `borg.nix`: shared Borg user, SSH key generation, and backup job defaults.
- `kuma-push.nix`: `dotfiles.kumaPush.units` pushes to an Uptime Kuma push monitor after each successful run of the listed services, and `dotfiles.kumaPush.postgresDumps.enable` adds a daily check that every `services.postgresqlBackup` dump is under 26 hours old. Push URLs contain the monitor token, so they live outside the repo in root-only `/var/lib/kuma-push/<service name>` files on each host; a missing file skips the push.

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

Homebrew packages, casks, and App Store apps are managed by nix-darwin in `hosts/darwin/configuration.nix`. Packages removed from this shared configuration are uninstalled from both Darwin hosts during activation.
