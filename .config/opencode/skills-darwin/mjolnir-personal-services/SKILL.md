---
name: mjolnir-personal-services
description: Use when changing, committing, releasing, or deploying the bingo_rust, budget, food_log, golf_rust, meals, receipt_breakdown, running, study, tally_rust, tracker, workout_rust, yahtzee_rust, or stock personal services on mjolnir from the Mac mini. Verifies and pushes application changes from ~/projects, updates the app's flake input in the Mac's ~/.dotfiles, deploys mjolnir remotely over SSH, verifies the service, and commits the lock update.
---

# Mjolnir Personal Services (from the Mac mini)

Ship an app change to mjolnir now and verify it, working from the Mac mini.
All edits, commits, and flake updates happen in the Mac's repositories; mjolnir
only builds and runs the result. Do not edit, commit, or pull in mjolnir's own
checkouts (`~/.dotfiles`, `~/projects/*` on mjolnir) as part of this workflow.

Without this, the weekly `update-nix-inputs` timer and Sunday auto-upgrade
deploy the change unverified within a week. By default, carry a successful
change all the way through without asking; "local only", "do not deploy", or
"do not commit" overrides that.

| Repository (`~/projects/`, Forgejo `jade/`) | Flake input | systemd service | Health check |
| --- | --- | --- | --- |
| `bingo_rust` | `bingoRust` | `bingo-rust` | `https://bingo.joejad.com/health` |
| `budget` | `budget` | `budget` | `https://budget.joejad.com/` |
| `food_log` | `foodLog` | `food-log` | `https://food.joejad.com/` |
| `golf_rust` | `golfRust` | `golf-rust` | `https://golf.joejad.com/ui` |
| `meals` | `mealPlanner` | `meal-planner` | `https://meals.joejad.com/health` |
| `receipt_breakdown` | `receiptBreakdown` | `receipt-breakdown` | `https://receipt.joejad.com/health` |
| `running` | `running` | `running` | `https://run.joejad.com/health` |
| `study` | `study` | `study` | `https://study.joejad.com/health` |
| `tally_rust` | `tallyRust` | `tally-rust` | `https://tally.joejad.com/health` |
| `tracker` | `tracker` | `tracker` | `https://track.joejad.com/` |
| `workout_rust` | `workoutRust` | `workout-rust` | `https://workout.joejad.com/` |
| `yahtzee_rust` | `yahtzeeRust` | `yahtzee-rust` | `https://yahtzee.joejad.com/health` |
| `stock` | `stock` | `stock` | systemd only |

Not for `wedding-rsvp`; it follows the reviewed promotion process in
`~/.dotfiles/nix/README.md`.

`mjolnir` is reachable as `ssh mjolnir` (user `jade`), with non-interactive
`sudo` there. If SSH fails, stop and report; do not change SSH or sudo config.

## 1. Verify And Push The App

1. Work in `~/projects/<repo>`. Its `origin` must be Forgejo
   (`ssh://forgejo@joejadserver.joejad.lan/jade/<repo>.git`). Some older Mac
   clones point at `git@git:repos/...` and are stale; if so, stop and ask
   rather than pushing there. If the repo is missing, clone it from Forgejo
   into `~/projects/<repo>`. Run `git pull --ff-only` before editing.
2. Follow the app's `AGENTS.md`. Run its format, lint, and test commands
   natively on the Mac (`cargo fmt --all -- --check`,
   `cargo clippy --all-targets --all-features -- -D warnings`, `cargo test`).
   App dev shells are Linux-only, so do not use `nix develop` here. If a check
   needs Linux or a local service, copy the tree to a fresh
   `mktemp -d` directory on mjolnir, run it there with `nix develop -c ...`,
   and remove only that directory afterward.
3. Build the exact package mjolnir deploys: evaluate on the Mac, build on
   mjolnir, against the nixpkgs pinned in dotfiles:

   ```bash
   nixpkgs_rev=$(jq -r '.nodes.nixpkgs.locked.rev' ~/.dotfiles/nix/flake.lock)
   nix build --no-link --print-out-paths --eval-store auto \
     --store ssh-ng://jade@mjolnir \
     --override-input nixpkgs "github:NixOS/nixpkgs/$nixpkgs_rev" \
     '.#packages.x86_64-linux.default'
   ```

4. The deployed branch is `main` on Forgejo `origin`. If the work is on
   another branch, stop and ask. Commit only the intended files, push `main`
   without force, and note `git rev-parse HEAD`.

## 2. Update The Input And Deploy

From `~/.dotfiles/nix` on the Mac:

1. `git pull --ff-only` first. Deploying from a stale checkout rolls back
   whatever mjolnir already runs. If `nix/` has unrelated uncommitted changes,
   stop and ask: the deploy builds the working tree, so they would ship too.
2. Update only the app's input and confirm the lock diff:

   ```bash
   nix flake update <input>
   git diff flake.lock   # only <input> changed, rev is the pushed commit
   ```

   Never run a bare `nix flake update` here; it pulls in unrelated upgrades.
3. Deploy remotely. Use the git flake reference `.#mjolnir`, not `path:.`,
   which cannot see the shared skills outside `nix/`:

   ```bash
   nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#mjolnir \
     --build-host jade@mjolnir --target-host jade@mjolnir --sudo --no-reexec
   ```

   Send long output to a file in the scratchpad and grep it for `error`,
   `Cannot build`, and `Done.` rather than reading it all.

## 3. Verify And Commit

1. Require `ssh mjolnir systemctl is-active <service>` and, where listed,
   `curl --fail <health check>` from the Mac to succeed. Also check
   `ssh mjolnir systemctl --failed` is empty.
2. On success, commit only `nix/flake.lock` as `Update <service> app source`
   and push dotfiles `main` without force.
3. On failure, check `ssh mjolnir systemctl status <service>` and
   `ssh mjolnir journalctl -u <service> -n 100`, leave `flake.lock`
   uncommitted, and report. Do not revert the pushed app commit.

Report the app checks, pushed commit, switch result, health checks, and
dotfiles commit.
