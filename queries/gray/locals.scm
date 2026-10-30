; Tree-sitter locals for Grayscale.
;
; Not required for highlighting, folds, or indentation. It enables scope-aware
; textobjects such as `@local.scope` and gives 'nvim-treesitter-textobjects'
; the definitions/references needed by its locals-based features.

; Scopes
(function_declaration) @local.scope
(block) @local.scope

; Definitions
(parameter
  name: (identifier) @local.definition)

(function_declaration
  name: (identifier) @local.definition)

(variable_declaration
  (identifier) @local.definition)

(field_declaration
  name: (identifier) @local.definition)

(alias_declaration
  name: (identifier) @local.definition)

(struct_declaration
  name: (identifier) @local.definition)

(enum_declaration
  name: (identifier) @local.definition)

; References
(identifier) @local.reference
