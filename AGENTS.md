# AGENTS.md - Development Guidelines for Dotfiles Repository

This document provides guidelines for agentic coding assistants working on this dotfiles repository. The repository contains NixOS configurations, shell scripts, and various tool configurations.

## Build, Lint, and Test Commands

### Nix Configuration Testing and Building

**Build a specific NixOS configuration:**
```bash
nixos-rebuild build --flake .#hostname
```

**Test a NixOS configuration (dry run):**
```bash
nixos-rebuild test --flake .#hostname
```

**Switch to a new NixOS configuration:**
```bash
sudo nixos-rebuild switch --flake .#hostname
```

**Build home-manager configuration:**
```bash
home-manager build --flake .#hostname
```

**Test home-manager configuration:**
```bash
home-manager switch --flake .#hostname
```

**Check Nix flake for syntax errors:**
```bash
nix flake check
```

**Update flake inputs:**
```bash
nix flake update
```

### Shell Script Linting and Testing

**Lint shell scripts with shellcheck:**
```bash
shellcheck scripts/*
shellcheck start/*.sh
```

**Run shell scripts in dry-run mode (if applicable):**
```bash
bash -n scripts/script_name
bash -n start/arch.sh
```

### Lua Code Linting and Formatting

**Lint Lua files (Neovim configs):**
```bash
luacheck .config/nvim/lua/
```

**Format Lua files with stylua:**
```bash
stylua --check .config/nvim/lua/
stylua .config/nvim/lua/
```

### General Repository Commands

**Check repository status:**
```bash
git status
```

**Run pre-commit checks (if configured):**
```bash
pre-commit run --all-files
```

## Code Style Guidelines

### Nix Code Style

**File Structure:**
- Use consistent indentation (2 spaces)
- Group related attributes together
- Use `inherit` for commonly used variables
- Prefer `let ... in` blocks for complex expressions

**Example:**
```nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  # Configuration here
}
```

**Naming Conventions:**
- Use `camelCase` for attribute names
- Use `snake_case` for variable names in `let` expressions
- Host names should be descriptive and lowercase
- Use meaningful names for derivations and packages

**Imports and Modules:**
- Group imports at the top
- Use relative imports when possible
- Follow the pattern: `{ config, pkgs, lib, ... }:`

**Error Handling:**
- Use `lib.mkIf` for conditional configurations
- Use `lib.mkDefault` for default values that can be overridden
- Validate inputs where appropriate

### Shell Script Style

**Shebang and Permissions:**
- Always include `#!/bin/bash` or `#!/bin/zsh`
- Ensure scripts are executable: `chmod +x script_name`

**Error Handling:**
```bash
set -euo pipefail
# Enable error checking
```

**Variable Naming:**
- Use `UPPER_CASE` for environment variables and constants
- Use `lower_case` for local variables
- Use descriptive names

**Example:**
```bash
#!/bin/bash
set -euo pipefail

readonly CONFIG_DIR="$HOME/.config"
local temp_file

function setup_config() {
  # Function implementation
}
```

**Best Practices:**
- Quote all variable expansions: `"$variable"`
- Use `[[ ]]` for string/file tests instead of `[ ]`
- Use functions for reusable code
- Add comments for complex logic

### Lua Code Style (Neovim Configuration)

**Formatting:**
- Use 2-space indentation
- Use consistent spacing around operators
- Follow the existing patterns in the codebase

**Structure:**
```lua
return {
  "plugin/name",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- Configuration here
  end,
}
```

**Naming Conventions:**
- Use `camelCase` for variables and functions
- Use `UPPER_CASE` for constants
- Use descriptive names

**Error Handling:**
- Use `pcall` for potentially failing operations
- Provide meaningful error messages

### General Guidelines

**File Organization:**
- Keep related configurations together
- Use descriptive directory structures
- Avoid deep nesting where possible

**Comments:**
- Use comments to explain complex logic
- Keep comments concise and meaningful
- Use `#` for shell scripts, `--` for Lua, `#` for Nix

**Security:**
- Never commit secrets or sensitive information
- Use proper file permissions for sensitive files
- Be cautious with executable permissions

**Git Workflow:**
- Use descriptive commit messages
- Follow conventional commit format when possible
- Keep commits focused on single changes

**Testing:**
- Test NixOS configurations in VMs before deploying
- Verify shell scripts on target systems
- Test Neovim configurations after changes

### Platform-Specific Considerations

**Linux (Arch/NixOS):**
- Test on target hardware when possible
- Verify package availability in repositories
- Check systemd service configurations

**macOS:**
- Use Homebrew for package management
- Test with aerospace instead of hyprland
- Verify macOS-specific paths and configurations

### Performance Considerations

**Nix:**
- Minimize rebuilds by using `lib.mkIf` for conditional logic
- Use `pkgs.callPackage` for custom derivations
- Cache frequently used expressions

**Shell Scripts:**
- Avoid unnecessary subprocess calls
- Use built-in shell features when possible
- Profile long-running scripts

**Neovim:**
- Lazy load plugins appropriately
- Minimize startup time impact
- Use efficient Lua patterns

This document should be updated as the codebase evolves and new patterns emerge.</content>
<parameter name="filePath">/Users/jade/.dotfiles/AGENTS.md