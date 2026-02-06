return {
  cmd = { 'biome', 'lsp-proxy' },
  filetypes = {
    'typescript', 'typescriptreact', 'javascript', 'javascriptreact',
    'json', 'jsonc', 'css',
  },
  root_markers = { 'biome.json', 'biome.jsonc', 'package.json', '.git' },
}
