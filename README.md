# NixOS Azure Dev VM

One-command setup for a fully-configured NixOS development VM on Azure.

**What you get:** 8 vCPU, 32GB RAM, Docker, Tailscale, Neovim, Node.js, Bun, and every dev tool you need — all declarative and reproducible.

**Cost:** ~$60/month (Azure B8as_v2 burstable)

## Quick start

### Option A: Let your AI agent do it

Tell your AI coding assistant (Claude Code, Cursor, etc.):

> "Set up a NixOS dev VM for me following the instructions at https://github.com/jorgensandhaug/nixos-azure-dev-vm/blob/main/AGENT.md"

The agent reads `AGENT.md` and handles everything. You just:
1. Click one Tailscale auth link
2. Paste one SSH key into GitHub

### Option B: Do it yourself

1. Create an Azure Gen2 VM (**Secure Boot must be disabled**):
   ```bash
   az vm create -g my-rg -n my-vm \
     --image Canonical:ubuntu-24_04-lts:server:latest \
     --size Standard_B8as_v2 \
     --security-type Standard \
     --ssh-key-values ~/.ssh/id_ed25519.pub
   ```

2. SSH in and run the bootstrap:
   ```bash
   ssh azureuser@<vm-ip> "curl -fsSL https://raw.githubusercontent.com/jorgensandhaug/nixos-azure-dev-vm/main/bootstrap.sh | \
     bash -s -- --ssh-key '$(cat ~/.ssh/id_ed25519.pub)' --hostname my-vm --username myname"
   ```

3. After reboot, set up Tailscale:
   ```bash
   ssh myname@<vm-ip> "sudo tailscale up --ssh --accept-routes"
   # Click the auth link it prints
   ```

4. Done! Remove the public IP for security.

## What's included

| Category | Packages |
|----------|----------|
| Editor | Neovim (default, with vi/vim aliases) |
| Search | ripgrep, fd, fzf, tree |
| JS/TS | Node.js 22, Bun, corepack |
| Docker | Docker Engine, docker-compose, lazydocker |
| Git | git, lazygit |
| System | htop, btop, tmux, curl, wget, jq |
| Infra | Tailscale VPN, systemd-networkd, earlyoom |
| Memory | zram swap (zstd, 25% of RAM) |

## Configuration

The bootstrap accepts these flags:

| Flag | Default | Description |
|------|---------|-------------|
| `--ssh-key` | (required) | Your SSH public key |
| `--hostname` | `dev-vm` | VM hostname |
| `--username` | `dev` | Unix username |
| `--timezone` | `UTC` | Timezone (e.g., `Europe/Stockholm`) |
| `--data-disk` | (none) | Format attached data disk as `/home` |

## Post-install extras

```bash
# Claude Code (AI coding assistant)
mkdir -p ~/.config/nixpkgs && echo '{ allowUnfree = true; }' > ~/.config/nixpkgs/config.nix
nix-env -iA nixpkgs.claude-code

# TypeScript native compiler
bun add -g @typescript/native-preview

# Your VM's SSH key (add to GitHub)
cat ~/.ssh/id_ed25519.pub
```

## How it works

The bootstrap script converts Ubuntu → NixOS in-place using the LUSTRATE method:

1. Installs Nix package manager on Ubuntu
2. Builds the full NixOS system from `configuration.nix.template`
3. Auto-detects filesystem UUIDs
4. Installs GRUB while preserving Ubuntu's EFI shim (required for Azure Hyper-V)
5. Reboots into NixOS

Key Azure/Hyper-V gotchas handled automatically:
- Uses `systemd-networkd` (dhcpcd breaks on Hyper-V)
- Preserves Ubuntu EFI shim chain (Hyper-V won't boot without it)
- Requires Secure Boot disabled (NixOS GRUB is unsigned)
- Waits for cloud-init to expand the root partition
- Serial console enabled for Azure boot diagnostics

## Customizing

Edit `configuration.nix.template` to add packages, services, or change settings. The `@@VARIABLE@@` placeholders are substituted by the bootstrap script.

## License

MIT
