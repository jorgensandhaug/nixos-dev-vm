return {
  cmd = { 'oxlint', '--lsp' },
  filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  root_markers = { '.oxlintrc.json', 'package.json', '.git' },
}
