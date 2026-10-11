---
name: mjolnir-personal-services
description: Use when changing, committing, releasing, or deploying the budget, food_log, golf_rust, meals, receipt, running, tally_rust, workout_rust, yahtzee_rust, or stock personal services on mjolnir. Verifies and pushes application changes, updates the app's flake input in ~/.dotfiles, deploys mjolnir, verifies the service, and commits the lock update.
---

# Mjolnir Personal Services

Ship an app change to mjolnir now and verify it. Without this, the weekly
`update-nix-inputs` timer and Sunday auto-upgrade deploy it unverified within
a week. By default, carry a successful change all the way through without
asking; "local only", "do not deploy", or "do not commit" overrides that.

| Repository (`~/projects/`, Forgejo `jade/`) | Flake input | systemd service | Health check |
| --- | --- | --- | --- |
| `budget` | `budget` | `budget` | `https://budget.joejad.com/` |
| `food_log` | `foodLog` | `food-log` | `https://food.joejad.com/` |
| `golf_rust` | `golfRust` | `golf-rust` | `https://golf.joejad.com/ui` |
| `meals` | `mealPlanner` | `meal-planner` | `https://meals.joejad.com/health` |
| `receipt` | `receipt` | `receipt` | `https://receipt.joejad.com/` |
| `running` | `running` | `running` | `https://run.joejad.com/health` |
| `tally_rust` | `tallyRust` | `tally-rust` | `https://tally.joejad.com/health` |
| `workout_rust` | `workoutRust` | `workout-rust` | `https://workout.joejad.com/` |
| `yahtzee_rust` | `yahtzeeRust` | `yahtzee-rust` | `https://yahtzee.joejad.com/health` |
| `stock` | `stock` | `stock` | systemd only |

Not for `wedding-rsvp`; it follows the reviewed promotion process in
`~/.dotfiles/nix/README.md`.

## 1. Verify And Push The App

1. Follow the app's `AGENTS.md`; run its format, lint, and test commands. Also
   run `nix build` in the repo, since its flake package and
   `nixosModules.default` are exactly what mjolnir deploys.
2. The deployed branch is `main` on the Forgejo `origin`. If the work is on
   another branch or the remote is missing, stop and ask.
3. Commit only the intended files, push `main` without force, and note
   `git rev-parse HEAD`.

## 2. Update The Input And Deploy

From `~/.dotfiles/nix`:

```bash
nix flake update <input>
git diff flake.lock   # only <input> changed, rev is the pushed commit
sudo nixos-rebuild switch --flake .#mjolnir
```

Never run a bare `nix flake update` here; it pulls in unrelated upgrades.
Leave unrelated dotfiles changes alone.

## 3. Verify And Commit

1. Require `systemctl is-active <service>` and, where listed,
   `curl --fail <health check>` to succeed.
2. On success, commit only `nix/flake.lock` as `Update <service> app source`
   and push dotfiles `main` without force.
3. On failure, check `systemctl status` and `journalctl -u <service>`, leave
   `flake.lock` uncommitted, and report. Do not revert the pushed app commit.

Report the app checks, pushed commit, switch result, health checks, and
dotfiles commit.
