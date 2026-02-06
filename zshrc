# Dotfiles-managed zshrc
# NixOS handles: autosuggestions, syntax-highlighting, zsh-vi-mode, starship, aliases

# History
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Autojump
[ -f /run/current-system/sw/share/autojump/autojump.zsh ] && source /run/current-system/sw/share/autojump/autojump.zsh
