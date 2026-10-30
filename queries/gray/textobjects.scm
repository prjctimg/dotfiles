; Tree-sitter textobjects for Grayscale.
;
; Consumed by 'nvim-treesitter-textobjects' and by 'mini.ai' specs such as the
; existing `F` object (`@function.outer` / `@function.inner`) in
; 'lua/plugins/mini.lua'.
;
; The inner captures use the `"{" _+ @inner "}"` shape recommended by
; nvim-treesitter: the braces are anonymous anchor tokens and `_+` captures the
; named nodes between them, so the selection excludes the delimiters.

; Functions -------------------------------------------------------------------
(function_declaration) @function.outer

(function_declaration
  (block
    .
    "{"
    _+ @function.inner
    "}"))

; Structs and enums (both act as "class" for textobject purposes) -------------
(struct_declaration) @class.outer

(struct_declaration
  "{"
  _+ @class.inner
  "}")

(enum_declaration) @class.outer

(enum_declaration
  "{"
  _+ @class.inner
  "}")

; Parameters ------------------------------------------------------------------
(parameter) @parameter.outer

(parameter
  (_) @parameter.inner)

; Conditionals ----------------------------------------------------------------
(if_statement) @conditional.outer

(if_statement
  (block
    .
    "{"
    _+ @conditional.inner
    "}"))

(when_statement) @conditional.outer

; Loops -----------------------------------------------------------------------
[
  (for_statement)
  (for_each_statement)
  (as_long_as_statement)
] @loop.outer

(for_statement
  (block
    .
    "{"
    _+ @loop.inner
    "}"))

(for_each_statement
  (block
    .
    "{"
    _+ @loop.inner
    "}"))

(as_long_as_statement
  (block
    .
    "{"
    _+ @loop.inner
    "}"))

(loop_statement) @loop.outer

(loop_statement
  (block
    .
    "{"
    _+ @loop.inner
    "}"))

; Comments --------------------------------------------------------------------
(comment) @comment.outer
(block_comment) @comment.outer

; Blocks ----------------------------------------------------------------------
(block) @block.outer

(block
  .
  "{"
  _+ @block.inner
  "}")
