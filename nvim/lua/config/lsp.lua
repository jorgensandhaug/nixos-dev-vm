-- Enable LSP servers (configs live in ~/.config/nvim/lsp/*.lua)
vim.lsp.enable('tsgo')

-- LSP keymaps (set when an LSP attaches to a buffer)
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
    end

    map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
    map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
    map('n', 'gr', vim.lsp.buf.references, 'References')
    map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
    map('n', 'gy', vim.lsp.buf.type_definition, 'Go to type definition')
    map('n', 'K', vim.lsp.buf.hover, 'Hover documentation')
    map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
    map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
    map('n', '[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
    map('n', ']d', vim.diagnostic.goto_next, 'Next diagnostic')
  end,
})

-- LSP timeout: stop servers after 5 min unfocused, restart on focus
local lsp_timeout_timer = nil
vim.api.nvim_create_autocmd('FocusLost', {
  callback = function()
    lsp_timeout_timer = vim.defer_fn(function()
      for _, client in ipairs(vim.lsp.get_clients()) do
        client:stop()
      end
    end, 1000 * 60 * 5) -- 5 minutes
  end,
})
vim.api.nvim_create_autocmd('FocusGained', {
  callback = function()
    if lsp_timeout_timer then
      lsp_timeout_timer:stop()
      lsp_timeout_timer = nil
    end
    -- Restart LSP if it was stopped
    if #vim.lsp.get_clients() == 0 then
      vim.cmd('edit') -- re-triggers LSP attach
    end
  end,
})

-- Minimal diagnostic display
vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = '●' },
  signs = true,
  underline = true,
  update_in_insert = false,
})
