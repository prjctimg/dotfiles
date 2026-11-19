-- ┌───────────────────────┐
-- │ C / C++ LSP (clangd)  │
-- └───────────────────────┘
--
-- clangd is enabled from 'lua/plugins/lsp.lua'. This file only adjusts the
-- command line; nvim-lspconfig already supplies the `c`, `cpp`, `objc`,
-- `objcpp` and `cuda` filetypes.
--
-- `--background-index` keeps a project-wide index under `.cache/clangd`, and
-- `--clang-tidy` surfaces the same diagnostics a build would report. Remove
-- `--clang-tidy` if it is too noisy on large third-party trees.
return {
  cmd = {
    'clangd',
    '--background-index',
    '--clang-tidy',
    '--header-insertion=iwyu',
    '--completion-style=detailed',
    '--pch-storage=memory',
  },
  init_options = {
    clangdFileStatus = true,
  },
}
