# Neovim Config

Minimal, RAM-efficient setup for code reading/navigation. Optimized for multiple instances.

## Structure

```
~/.config/nvim/          # Symlinked to ~/dotfiles/nvim
├── init.lua             # Bootstrap lazy.nvim, load config/*
├── lua/config/
│   ├── options.lua      # vim.opt settings
│   ├── keymaps.lua      # Window/buffer navigation
│   └── lsp.lua          # LSP enable + keymaps + timeout logic
├── lua/plugins/         # lazy.nvim auto-discovers *.lua here
│   ├── fzf-lua.lua
│   ├── nvim-tree.lua
│   └── treesitter.lua
└── lsp/                 # Neovim 0.11+ native LSP configs
    ├── tsgo.lua         # TypeScript (native preview)
    ├── biome.lua        # Formatter (TS/JS/JSON/CSS)
    └── oxlint.lua       # Linter (TS/JS)
```

## LSP Servers

| Server | Command | Purpose |
|--------|---------|---------|
| tsgo | `tsgo --lsp --stdio` | TS/JS type checking, go-to-def |
| biome | `biome lsp-proxy` | Formatting |
| oxlint | `oxlint --lsp` | Linting |

**Important**: tsgo uses `--lsp` as a FLAG, not subcommand. `tsgo lsp --stdio` is WRONG.

## Key Bindings

| Key | Action |
|-----|--------|
| `Space ff` / `Ctrl+p` | Find files |
| `Space fg` | Live grep (project search) |
| `Space e` | Toggle file tree |
| `gd` | Go to definition |
| `gr` | References |
| `K` | Hover docs |
| `Space cf` | Format file |
| `Space ca` | Code action |
| `Ctrl+h/j/k/l` | Navigate windows |

## Prerequisites

```bash
brew install neovim fzf fd ripgrep tree-sitter-cli
bun add -g @typescript/native-preview @biomejs/biome oxlint
```

## Adding a New LSP

1. Create `lsp/<name>.lua`:
   ```lua
   return {
     cmd = { 'binary', '--args' },
     filetypes = { 'typescript', ... },
     root_markers = { 'config.json', '.git' },
   }
   ```
2. Add `vim.lsp.enable('<name>')` in `lua/config/lsp.lua` (both at top AND in FocusGained handler)

## RAM Optimization

LSP servers auto-stop after 5 min unfocused (see `lua/config/lsp.lua` FocusLost/FocusGained handlers). They restart on focus.

## Treesitter

Uses new nvim-treesitter (main branch). Requires `tree-sitter-cli` for compiling parsers. Install parsers via `:TSInstall <lang>`.
