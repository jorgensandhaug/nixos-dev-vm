#!/usr/bin/env bash
#
# NixOS Azure Bootstrap
# Converts a fresh Ubuntu Azure Gen2 VM into a fully-configured NixOS machine.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jorgensandhaug/dotfiles/main/nixos/bootstrap.sh | \
#     bash -s -- --ssh-key "ssh-ed25519 AAAA..." --hostname "my-vm" --username "myuser"
#
# Requirements:
#   - Fresh Ubuntu 22.04/24.04 Azure Gen2 VM
#   - Secure Boot DISABLED at VM creation
#   - At least 30GB OS disk
#   - SSH access as a sudo-capable user
#
set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────
HOSTNAME="dev-vm"
USERNAME="dev"
SSH_PUBKEY=""
TIMEZONE="UTC"
DATA_DISK_SIZE=""  # empty = no data disk setup
REPO_URL="https://raw.githubusercontent.com/jorgensandhaug/dotfiles/main"
REPO_GIT="https://github.com/jorgensandhaug/dotfiles.git"
NIXOS_CHANNEL="nixos-24.11"

# ── Parse arguments ──────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh-key)      SSH_PUBKEY="$2"; shift 2 ;;
    --hostname)     HOSTNAME="$2"; shift 2 ;;
    --username)     USERNAME="$2"; shift 2 ;;
    --timezone)     TIMEZONE="$2"; shift 2 ;;
    --data-disk)    DATA_DISK_SIZE="$2"; shift 2 ;;
    --channel)      NIXOS_CHANNEL="$2"; shift 2 ;;
    *)              echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$SSH_PUBKEY" ]]; then
  echo "ERROR: --ssh-key is required"
  echo "Usage: bootstrap.sh --ssh-key \"ssh-ed25519 AAAA...\" [--hostname name] [--username user] [--timezone TZ]"
  exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "  NixOS Azure Bootstrap"
echo "═══════════════════════════════════════════════════════════"
echo "  Hostname:  $HOSTNAME"
echo "  Username:  $USERNAME"
echo "  Timezone:  $TIMEZONE"
echo "  Channel:   $NIXOS_CHANNEL"
echo "═══════════════════════════════════════════════════════════"

# ── Step 0: Verify environment ───────────────────────────────────
echo ""
echo "▶ Verifying environment..."

if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
  echo "ERROR: This script must run on a fresh Ubuntu VM."
  exit 1
fi

if [[ ! -d /sys/firmware/efi ]]; then
  echo "ERROR: This VM is not EFI-booted. Use an Azure Gen2 VM."
  exit 1
fi

# ── Step 1: Wait for cloud-init to finish ────────────────────────
echo ""
echo "▶ Waiting for cloud-init to complete (partition expansion)..."
cloud-init status --wait 2>/dev/null || true
echo "  Cloud-init done. Root partition: $(df -h / | awk 'NR==2{print $2}')"

# ── Step 2: Detect filesystem UUIDs ──────────────────────────────
echo ""
echo "▶ Detecting filesystem UUIDs..."

ROOT_DEV=$(findmnt -n -o SOURCE /)
BOOT_DEV=$(findmnt -n -o SOURCE /boot 2>/dev/null || echo "")
EFI_DEV=$(findmnt -n -o SOURCE /boot/efi 2>/dev/null || echo "")

ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEV")
echo "  Root: $ROOT_DEV → $ROOT_UUID"

if [[ -n "$BOOT_DEV" ]]; then
  BOOT_UUID=$(blkid -s UUID -o value "$BOOT_DEV")
  echo "  Boot: $BOOT_DEV → $BOOT_UUID"
else
  # Some Ubuntu setups don't have a separate /boot
  echo "  WARNING: No separate /boot partition found."
  echo "  Looking for boot partition on disk..."
  DISK=$(lsblk -ndo pkname "$ROOT_DEV")
  BOOT_DEV=$(lsblk -nlo NAME,LABEL "/dev/$DISK" | grep -i boot | head -1 | awk '{print "/dev/"$1}')
  if [[ -n "$BOOT_DEV" ]]; then
    BOOT_UUID=$(blkid -s UUID -o value "$BOOT_DEV")
    echo "  Boot: $BOOT_DEV → $BOOT_UUID"
  else
    echo "  ERROR: Cannot find boot partition."
    exit 1
  fi
fi

if [[ -n "$EFI_DEV" ]]; then
  EFI_UUID=$(blkid -s UUID -o value "$EFI_DEV")
  echo "  EFI:  $EFI_DEV → $EFI_UUID"
else
  DISK=$(lsblk -ndo pkname "$ROOT_DEV")
  EFI_DEV=$(lsblk -nlo NAME,FSTYPE "/dev/$DISK" | grep vfat | head -1 | awk '{print "/dev/"$1}')
  if [[ -n "$EFI_DEV" ]]; then
    EFI_UUID=$(blkid -s UUID -o value "$EFI_DEV")
    echo "  EFI:  $EFI_DEV → $EFI_UUID"
    sudo mount "$EFI_DEV" /boot/efi 2>/dev/null || true
  else
    echo "  ERROR: Cannot find EFI partition."
    exit 1
  fi
fi

# ── Step 3: Format data disk (if attached and requested) ────────
if [[ -n "$DATA_DISK_SIZE" ]]; then
  echo ""
  echo "▶ Setting up data disk..."
  # Find the unformatted data disk (not the OS disk)
  OS_DISK=$(lsblk -ndo pkname "$ROOT_DEV")
  DATA_DISK=$(lsblk -ndo NAME,TYPE | grep disk | grep -v "$OS_DISK" | grep -v "sr0" | head -1 | awk '{print $1}')
  if [[ -n "$DATA_DISK" ]]; then
    echo "  Found data disk: /dev/$DATA_DISK"
    if ! blkid "/dev/$DATA_DISK" | grep -q home-data; then
      echo "  Formatting /dev/$DATA_DISK with ext4 (label: home-data)..."
      sudo mkfs.ext4 -L home-data "/dev/$DATA_DISK"
    else
      echo "  Data disk already formatted."
    fi
  else
    echo "  WARNING: No data disk found. Skipping."
  fi
fi

# ── Step 4: Install Nix ──────────────────────────────────────────
echo ""
echo "▶ Installing Nix package manager..."
if ! command -v nix &>/dev/null; then
  sh <(curl -fsSL https://nixos.org/nix/install) --no-daemon
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
else
  echo "  Nix already installed."
  . "$HOME/.nix-profile/etc/profile.d/nix.sh" 2>/dev/null || true
fi

# ── Step 5: Set up NixOS channel ─────────────────────────────────
echo ""
echo "▶ Setting up NixOS channel ($NIXOS_CHANNEL)..."
nix-channel --add "https://nixos.org/channels/$NIXOS_CHANNEL" nixos
nix-channel --add "https://nixos.org/channels/nixpkgs-unstable" nixpkgs
nix-channel --update

# ── Step 6: Download and configure NixOS ─────────────────────────
echo ""
echo "▶ Generating NixOS configuration..."
sudo mkdir -p /etc/nixos

# Download template
curl -fsSL "$REPO_URL/nixos/configuration.nix.template" -o /tmp/configuration.nix.template

# Substitute variables
sed \
  -e "s|@@HOSTNAME@@|$HOSTNAME|g" \
  -e "s|@@USERNAME@@|$USERNAME|g" \
  -e "s|@@SSH_PUBKEY@@|$SSH_PUBKEY|g" \
  -e "s|@@TIMEZONE@@|$TIMEZONE|g" \
  -e "s|@@ROOT_UUID@@|$ROOT_UUID|g" \
  -e "s|@@BOOT_UUID@@|$BOOT_UUID|g" \
  -e "s|@@EFI_UUID@@|$EFI_UUID|g" \
  /tmp/configuration.nix.template | sudo tee /etc/nixos/configuration.nix > /dev/null

echo "  Configuration written to /etc/nixos/configuration.nix"

# ── Step 7: Build NixOS system ───────────────────────────────────
echo ""
echo "▶ Building NixOS system (this takes a few minutes)..."
export NIX_PATH="nixpkgs=$HOME/.nix-profile/share/nix/nixpkgs:nixos=$HOME/.nix-profile/share/nix/nixos:nixos-config=/etc/nixos/configuration.nix"

# Find nixpkgs path from channel
NIXPKGS_PATH=$(nix-instantiate --eval -E '<nixos>' 2>/dev/null | tr -d '"' || true)
if [[ -z "$NIXPKGS_PATH" || ! -d "$NIXPKGS_PATH" ]]; then
  NIXPKGS_PATH=$(readlink -f "$HOME/.nix-profile/share/nix/nixos" 2>/dev/null || echo "")
fi
if [[ -z "$NIXPKGS_PATH" || ! -d "$NIXPKGS_PATH" ]]; then
  # Fall back to channel store path
  CHANNEL_LINK=$(readlink "$HOME/.nix-defexpr/channels/nixos" 2>/dev/null || readlink "$HOME/.nix-profile" 2>/dev/null)
  NIXPKGS_PATH=$(find /nix/var/nix/profiles/per-user -path '*/channels/nixos' -exec readlink -f {} \; 2>/dev/null | head -1)
fi

SYSTEM_BUILD=$(nix-build '<nixos/nixos>' -A system --no-out-link \
  -I "nixos-config=/etc/nixos/configuration.nix" 2>&1 | tee /dev/stderr | tail -1)

echo "  System built: $SYSTEM_BUILD"

# ── Step 8: Install NixOS (LUSTRATE method) ──────────────────────
echo ""
echo "▶ Installing NixOS to disk..."

# Set system profile
sudo nix-env -p /nix/var/nix/profiles/system --set "$SYSTEM_BUILD"

# Create NIXOS marker and LUSTRATE list
sudo touch /etc/NIXOS
# LUSTRATE: on next boot, NixOS moves everything listed here to /old-root
cat <<'LUSTRATE' | sudo tee /etc/NIXOS_LUSTRATE > /dev/null
etc/nixos
LUSTRATE

# Run switch-to-configuration to install bootloader
echo "  Installing GRUB bootloader..."
sudo NIXOS_INSTALL_BOOTLOADER=1 "$SYSTEM_BUILD/bin/switch-to-configuration" boot

echo "  NixOS installed successfully!"

# ── Step 9: Clone dotfiles and symlink configs ───────────────────
echo ""
echo "▶ Installing dotfiles (nvim, tmux)..."
DOTFILES_DIR="/home/$USERNAME/dotfiles"

# Clone the repo
sudo -u "$USERNAME" git clone "$REPO_GIT" "$DOTFILES_DIR" 2>/dev/null || {
  echo "  Repo already cloned, pulling latest..."
  sudo -u "$USERNAME" git -C "$DOTFILES_DIR" pull
}

# Symlink nvim config
sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.config"
if [[ -e "/home/$USERNAME/.config/nvim" ]]; then
  echo "  Backing up existing nvim config to ~/.config/nvim.bak"
  sudo -u "$USERNAME" mv "/home/$USERNAME/.config/nvim" "/home/$USERNAME/.config/nvim.bak"
fi
sudo -u "$USERNAME" ln -sf "$DOTFILES_DIR/nvim" "/home/$USERNAME/.config/nvim"
echo "  Neovim config symlinked."

# Symlink tmux config
if [[ -e "/home/$USERNAME/.tmux.conf" ]]; then
  echo "  Backing up existing tmux.conf to ~/.tmux.conf.bak"
  sudo -u "$USERNAME" mv "/home/$USERNAME/.tmux.conf" "/home/$USERNAME/.tmux.conf.bak"
fi
sudo -u "$USERNAME" ln -sf "$DOTFILES_DIR/tmux.conf" "/home/$USERNAME/.tmux.conf"
echo "  tmux config symlinked."

sudo chown -R "$USERNAME:users" "/home/$USERNAME/.config" "$DOTFILES_DIR"
echo "  Dotfiles installed."

# ── Step 10: Reboot ──────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  NixOS installation complete!"
echo ""
echo "  The VM will now reboot into NixOS."
echo ""
echo "  After reboot:"
echo "    1. SSH in:  ssh ${USERNAME}@<ip>"
echo "    2. Run:     sudo tailscale up --ssh --accept-routes"
echo "    3. Authenticate Tailscale in browser"
echo "═══════════════════════════════════════════════════════════"

echo ""
echo "Rebooting in 5 seconds..."
sleep 5
sudo reboot
