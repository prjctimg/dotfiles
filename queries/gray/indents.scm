; Tree-sitter indentation for Grayscale.
;
; Used by `indentexpr = v:lua.require'nvim-treesitter'.indentexpr()` in
; 'after/ftplugin/gray.lua'.
;
; The grammar represents every `{ ... }` body as a `block`. Array, map and
; struct literals also use braces (Gray does not use `[...]` for arrays), and
; attributes use `#[...]`. `@indent.branch` marks the closing delimiter as the
; start of a dedented line; `@indent.end` ends the indent range. Both are needed
; (same shape as the upstream Go query). `parameter_list` has no delimiters of
; its own -- the parentheses belong to `function_declaration` -- so it is not
; captured here.
[
  (block)
  (struct_declaration)
  (enum_declaration)
  (array_literal)
  (map_literal)
  (struct_literal)
  (attribute_list)
] @indent.begin

(block
  "}" @indent.branch)

(struct_declaration
  "}" @indent.branch)

(enum_declaration
  "}" @indent.branch)

(array_literal
  "}" @indent.branch)

(map_literal
  "}" @indent.branch)

(struct_literal
  "}" @indent.branch)

(attribute_list
  "]" @indent.branch)

[
  "}"
  "]"
  ")"
] @indent.end

(block_comment) @indent.ignore
