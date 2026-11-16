-- OLS (Odin Language Server) configuration.
-- Uses the Odin installation extracted to ~/.local/share/odin.
local odin_root = vim.fs.joinpath(vim.fn.expand('~'), '.local', 'share', 'odin')

return {
  init_options = {
    enable_document_symbols = true,
    enable_hover = true,
    enable_snippets = true,
    enable_inlay_hints = true,
    enable_fake_methods = true,
    enable_procedure_snippet = true,
    enable_references = true,
    enable_rename = true,
    enable_format = true,
    enable_auto_import = true,
    collections = {
      { name = 'core', path = odin_root .. '/core' },
      { name = 'vendor', path = odin_root .. '/vendor' },
      { name = 'base', path = odin_root .. '/base' },
    },
  },
}
