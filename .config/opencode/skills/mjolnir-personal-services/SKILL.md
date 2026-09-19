---
name: mjolnir-personal-services
description: Use when changing, committing, releasing, or deploying the budget, food_log, golf_rust, receipt, running, workout_rust, or stock personal services on mjolnir. Verifies and pushes application changes, updates the matching source pin in ~/.dotfiles, deploys mjolnir, verifies the service, and persists the dotfiles update.
---

# Mjolnir Personal Services

Use this workflow after making code changes in one of the mapped personal
service repositories. The user's default preference is to carry successful
changes through commit, source pinning, deployment, verification, and the
dotfiles commit without asking again. An explicit request such as "local
only", "do not deploy", or "do not commit" overrides that default.

## Scope

| Local repository | Forgejo repository | Nix source attribute | systemd service | Health check |
| --- | --- | --- | --- | --- |
| `budget` | `budget` | `budget` | `budget` | `https://budget.joejad.com/` |
| `food_log` | `food_log` | `foodLog` | `food-log` | `https://food.joejad.com/` |
| `golf_rust` | `golf_rust` | `golfRust` | `golf-rust` | `https://golf.joejad.com/ui` |
| `receipt` | `receipt` | `receipt` | `receipt` | `https://receipt.joejad.com/` |
| `running` | `running` | `running` | `running` | `https://run.joejad.com/` |
| `workout_rust` | `workout_rust` | `workoutRust` | `workout-rust` | `https://workout.joejad.com/` |
| `stock` | `stock` | `stock` | `stock` | systemd only |

The source file is
`~/.dotfiles/nix/hosts/mjolnir/personal-sources.nix`. Forgejo repositories are
under `http://joejadserver.joejad.lan:3000/jade` for Nix fetches and normally
use an `origin` SSH remote for pushes.

Do not use this workflow for `wedding-rsvp`. Its pin is deliberately excluded
from the generic source updater and requires the reviewed promotion process in
`~/.dotfiles/nix/README.md`.

## 1. Identify And Verify The Application

1. Read the application's `AGENTS.md` and follow its repository-specific
   checks and conventions.
2. Confirm the repository by inspecting its root, current branch, and remotes;
   do not rely only on the directory name.
3. Complete the requested implementation and all applicable formatting,
   linting, and test commands before publishing anything.
4. Inspect `git status --short`, `git diff`, and `git log --oneline -10`.
   Preserve unrelated user or agent changes and stage only intended files.
5. The Nix pin follows `main`. If the change is not on `main`, or the expected
   Forgejo remote is missing, stop and ask rather than merging, force-pushing,
   or guessing.

Do not proceed to source pinning when application checks fail.

## 2. Publish The Application

1. Create a concise commit matching the repository's history.
2. Push `main` to the Forgejo remote without force.
3. Record the full pushed commit with `git rev-parse HEAD` and ensure the push
   succeeded before calculating a Nix hash.

The standing workflow preference above is authorization for these commit and
push steps when the skill is triggered by a request that changes a scoped
service. Never include unrelated work in the commit.

## 3. Update Only The Matching Source Pin

From `~/.dotfiles`, prefetch the changed repository only:

```bash
nix flake prefetch --refresh --json "git+http://joejadserver.joejad.lan:3000/jade/<repo>.git?ref=main"
```

Use `.locked.rev` and `.hash` from the JSON. Confirm the fetched revision is
the pushed application commit, then update only the mapped attribute in
`nix/hosts/mjolnir/personal-sources.nix`.

Do not run `scripts/update-mjolnir-personal-sources` for a single application;
it refreshes every personal source and can introduce unrelated upgrades. Do
not modify any other source pin unless the user explicitly requests a bulk
update.

Before deployment:

1. Inspect the dotfiles worktree and its recent history.
2. Do not stage or alter unrelated dotfiles changes.
3. Run `git diff --check`.
4. Evaluate the host configuration from `~/.dotfiles/nix`:

```bash
nix eval --raw .#nixosConfigurations.mjolnir.config.system.build.toplevel.drvPath
```

Stop if the source revision or hash does not evaluate correctly.

## 4. Deploy And Verify

Deploy the evaluated working tree:

```bash
sudo nixos-rebuild switch --flake ~/.dotfiles/nix#mjolnir
```

After a successful switch:

1. Require `systemctl is-active <service>` to report `active`.
2. For services with an HTTP health check, use `curl --fail` and require a
   successful response from the mapped URL.
3. For `stock`, verify systemd state only because it has no HTTP endpoint.
4. If verification fails, inspect service status and recent journal output.
   Diagnose the failure without destructive Git operations and do not claim a
   successful deployment.

## 5. Persist The Dotfiles Pin

Only after deployment and health checks succeed:

1. Reinspect `git status`, `git diff`, and `git log --oneline -10` in
   `~/.dotfiles`.
2. Stage only `nix/hosts/mjolnir/personal-sources.nix`.
3. Commit with a concise message such as `Update <service> app source`.
4. Push dotfiles `main` to its normal remote without force.
5. Confirm both application and dotfiles worktrees contain no unintended
   remaining changes.

If deployment fails, leave the source-pin change uncommitted, report the
failure and current application commit, and continue diagnosis when feasible.
Do not silently revert the already-pushed application commit or unrelated
work.

## Completion Report

Report:

- application checks run and their outcome;
- application commit and push result;
- pinned revision and NAR hash;
- NixOS switch result;
- systemd and HTTP verification results;
- dotfiles commit and push result;
- any remaining worktree changes or blockers.
