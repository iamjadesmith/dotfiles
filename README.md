# Requirements

- Install git
- Install stow

## Installation

### Install Zoxide first

Debian

```bash
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
```

Otherwise, install with your package manager

```bash
git clone git@github.com:iamjadesmith/dotfiles.git && cd dotfiles
```

Then use GNU stow to create symlinks

```bash
stow .
```

## Installing Other Things

### Neovim

For [Neovim](https://github.com/iamjadesmith/neovim), Look at my github

### TPM (for tmux)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Run tmux and hit `prefix` + `I` to install tmux plugins (`prefix` should be `space`)

## Reference

[Link to Dreams of Autonomy Video for Dotfiles](https://www.youtube.com/watch?v=y6XCebnB9gs)
