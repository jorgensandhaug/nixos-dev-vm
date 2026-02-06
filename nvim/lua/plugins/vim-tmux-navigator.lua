return {
  'christoomey/vim-tmux-navigator',
  lazy = false, -- Load immediately for keybindings to work
  keys = {
    { '<C-h>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Navigate left (nvim/tmux)' },
    { '<C-j>', '<cmd>TmuxNavigateDown<cr>', desc = 'Navigate down (nvim/tmux)' },
    { '<C-k>', '<cmd>TmuxNavigateUp<cr>', desc = 'Navigate up (nvim/tmux)' },
    { '<C-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Navigate right (nvim/tmux)' },
  },
}
