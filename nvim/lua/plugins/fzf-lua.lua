return {
  'ibhagwan/fzf-lua',
  cmd = 'FzfLua',
  keys = {
    { '<leader>ff', '<cmd>FzfLua files<cr>', desc = 'Find files' },
    { '<leader>fg', '<cmd>FzfLua live_grep<cr>', desc = 'Live grep' },
    { '<leader>fb', '<cmd>FzfLua buffers<cr>', desc = 'Find buffers' },
    { '<leader>fh', '<cmd>FzfLua help_tags<cr>', desc = 'Help tags' },
    { '<leader>fr', '<cmd>FzfLua oldfiles<cr>', desc = 'Recent files' },
    { '<leader>fw', '<cmd>FzfLua grep_cword<cr>', desc = 'Grep word under cursor' },
    { '<C-p>', '<cmd>FzfLua files<cr>', desc = 'Find files (Ctrl+P)' },
  },
  opts = {
    winopts = {
      height = 0.85,
      width = 0.80,
      preview = {
        layout = 'vertical',
        vertical = 'down:45%',
      },
    },
    files = {
      fd_opts = '--type f --hidden --follow --exclude .git --exclude node_modules',
    },
    grep = {
      rg_opts = '--column --line-number --no-heading --color=always --smart-case --hidden --glob=!.git --glob=!node_modules',
    },
  },
}
