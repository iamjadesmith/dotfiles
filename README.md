# README

## Prerequisites

- Install git
- Install stow
- Install fzf
- Install zoxide
- Install tmux
- Install oh-my-posh
- Install JetBrains Mono Nerd Font

Installing Zoxide on Debian

```bash
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
```

## Installation

Clone the dotfiles and change into the `.dotfiles` directory

```bash
git clone git@github.com:iamjadesmith/dotfiles.git ~/.dotfiles && cd ~/.dotfiles
```

Then use GNU stow to create symlinks

```bash
stow .
```

## Installing Other Things

### TPM (for tmux)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Run tmux and hit `prefix` + `I` to install tmux plugins (`prefix` should be `ctrl` + `space`)

## Reference

[Link to Dreams of Autonomy Video for Dotfiles](https://www.youtube.com/watch?v=y6XCebnB9gs)
