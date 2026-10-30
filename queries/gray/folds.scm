; Tree-sitter folds for Grayscale.
;
; Upstream 'tree-sitter-gray' only ships highlights.scm. Neovim derives folds
; from a `folds` query when 'foldexpr' is `v:lua.vim.treesitter.foldexpr()`.
;
; Every statement body in the grammar is a `block`, so folding blocks covers
; function bodies, if/or/elif/else branches, loops, when/is clauses and bare
; blocks. Struct and enum bodies are not blocks, so they are listed separately.
; Multi-line literals and block comments fold too.
[
  (block)
  (struct_declaration)
  (enum_declaration)
  (array_literal)
  (map_literal)
  (struct_literal)
  (block_comment)
] @fold
