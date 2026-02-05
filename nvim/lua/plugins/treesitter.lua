return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = 'BufReadPost',
  config = function()
    -- New nvim-treesitter API: just install parsers.
    -- Highlighting is built into Neovim via vim.treesitter.start()
    require('nvim-treesitter').setup()

    -- Auto-enable treesitter highlighting for supported filetypes
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
      end,
    })
  end,
}
