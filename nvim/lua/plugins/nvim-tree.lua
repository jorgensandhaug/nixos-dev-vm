return {
  'nvim-tree/nvim-tree.lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  cmd = { 'NvimTreeToggle', 'NvimTreeFocus' },
  keys = {
    { '<leader>e', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle file explorer' },
  },
  opts = {
    filters = {
      dotfiles = false,
      custom = { '.git', 'node_modules', '.cache' },
    },
    view = {
      width = 30,
      side = 'left',
    },
    renderer = {
      icons = {
        show = {
          file = true,
          folder = true,
          folder_arrow = true,
          git = false,
        },
      },
    },
    actions = {
      open_file = {
        quit_on_open = false,
      },
    },
  },
}
