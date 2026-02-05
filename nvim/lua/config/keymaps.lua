local map = vim.keymap.set

-- Better window navigation
map('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Move to lower window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Move to upper window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Buffer navigation
map('n', '<leader>q', '<cmd>bd<cr>', { desc = 'Close buffer' })
map('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Previous buffer' })
map('n', '<S-l>', '<cmd>bnext<cr>', { desc = 'Next buffer' })

-- Clear search highlight on Escape
map('n', '<Esc>', '<cmd>nohlsearch<cr>')

-- Better indenting (stay in visual mode)
map('v', '<', '<gv')
map('v', '>', '>gv')
