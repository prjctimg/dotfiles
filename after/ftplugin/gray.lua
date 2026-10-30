-- ┌────────────────────┐
-- │ Grayscale ('gray') │
-- └────────────────────┘
--
-- Buffer-local behavior for Grayscale source. The filetype is shared by
-- '*.gray' and '*.grayscale' (see `vim.filetype.add()` in 'init.lua').

-- `gray fmt` normalizes to four spaces, so edit with the same width instead of
-- the two-space default from 'lua/options.lua'; otherwise every save visibly
-- reindents the buffer.
vim.bo.expandtab = true
vim.bo.shiftwidth = 4
vim.bo.tabstop = 4
vim.bo.softtabstop = 4

-- Line and block comments, for 'mini.comment' (`gc`), `gq`, and `o`/`O`.
vim.bo.commentstring = '// %s'
vim.bo.comments = 's1:/*,mb:*,ex:*/'

-- '-' is subtraction in Grayscale, not part of an identifier. The global
-- 'iskeyword' intentionally includes it for prose textobjects, which would make
-- `a-b` a single word here.
vim.bo.iskeyword = '@,48-57,_,192-255'

-- Tree-sitter folding and indentation. `vim.treesitter.foldexpr()` reads
-- 'queries/gray/folds.scm'; `nvim-treesitter.indentexpr()` reads
-- 'queries/gray/indents.scm'. Both need the parser installed, so leave the
-- global 'indent' foldmethod in place until it is.
if pcall(vim.treesitter.language.add, 'gray') then
  vim.wo.foldmethod = 'expr'
  vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end
