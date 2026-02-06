local map = vim.keymap.set

-- Window navigation handled by vim-tmux-navigator plugin
-- (seamlessly moves between nvim windows AND tmux panes)

-- Buffer navigation
map('n', '<leader>q', '<cmd>bd<cr>', { desc = 'Close buffer' })
map('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Previous buffer' })
map('n', '<S-l>', '<cmd>bnext<cr>', { desc = 'Next buffer' })

-- Clear search highlight on Escape
map('n', '<Esc>', '<cmd>nohlsearch<cr>')

-- Better indenting (stay in visual mode)
map('v', '<', '<gv')
map('v', '>', '>gv')

-- Save & quit shortcuts
map('n', '<C-s>', '<cmd>wa<cr>', { desc = 'Save all' })
map('i', '<C-s>', '<Esc><cmd>wa<cr>', { desc = 'Save all' })
map('n', '<leader>wq', '<cmd>wa<cr><cmd>qa<cr>', { desc = 'Save all & quit' })
map('n', '<leader>qq', '<cmd>qa!<cr>', { desc = 'Quit all (discard changes)' })
