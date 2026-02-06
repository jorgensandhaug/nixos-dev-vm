#!/usr/bin/env bash
#
# Dotfiles setup script
# Works on macOS and Linux (including NixOS)
#
# Usage:
#   git clone https://github.com/jorgensandhaug/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && ./setup.sh
#
# Or one-liner:
#   curl -fsSL https://raw.githubusercontent.com/jorgensandhaug/dotfiles/main/setup.sh | bash
#
set -euo pipefail

REPO_URL="https://github.com/jorgensandhaug/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# ── Clone repo if not already in it ──────────────────────────────
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  echo "▶ Cloning dotfiles repo..."
  if command -v git &>/dev/null; then
    git clone "$REPO_URL" "$DOTFILES_DIR"
  else
    echo "ERROR: git is not installed."
    exit 1
  fi
else
  echo "▶ Dotfiles repo already exists at $DOTFILES_DIR"
fi

# ── Helper: symlink with backup ──────────────────────────────────
link_file() {
  local src="$1"
  local dst="$2"

  if [[ -L "$dst" ]]; then
    # Already a symlink — remove and re-link
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    echo "  Backing up $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi

  ln -sf "$src" "$dst"
  echo "  Linked $dst → $src"
}

# ── Symlink nvim config ──────────────────────────────────────────
echo "▶ Setting up Neovim config..."
mkdir -p "$HOME/.config"
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# ── Symlink tmux config ──────────────────────────────────────────
echo "▶ Setting up tmux config..."
link_file "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

echo ""
echo "Done! Dotfiles installed."
