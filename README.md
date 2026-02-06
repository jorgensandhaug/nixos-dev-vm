# Dotfiles

Personal dotfiles: Neovim, tmux, and NixOS dev VM bootstrap.

## Quick Setup

```bash
curl -fsSL https://raw.githubusercontent.com/jorgensandhaug/nixos-dev-vm/main/setup.sh | bash
```

Or manually:

```bash
git clone https://github.com/jorgensandhaug/nixos-dev-vm.git ~/dotfiles
cd ~/dotfiles && ./setup.sh
```

This symlinks:
- `~/.config/nvim` -> `~/dotfiles/nvim`
- `~/.tmux.conf` -> `~/dotfiles/tmux.conf`

Existing configs are backed up with a `.bak` suffix.

## Structure

```
nvim/           Neovim config (lazy.nvim)
tmux.conf       tmux configuration
nixos/          NixOS Azure VM bootstrap
  bootstrap.sh  Converts Ubuntu VM to NixOS
  configuration.nix.template
  AGENT.md      AI agent instructions for VM setup
  README.md     NixOS-specific docs
setup.sh        Dotfiles installer (macOS + Linux)
```

## NixOS Dev VM

See [nixos/README.md](nixos/README.md) for one-command NixOS VM setup on Azure.
