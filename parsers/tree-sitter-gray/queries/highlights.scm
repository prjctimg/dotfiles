; Identifiers (fallback) - MUST BE FIRST so specific patterns override
(identifier) @variable

; Comments
(comment) @comment
(block_comment) @comment

; Strings
(string) @string
(string_content) @string
(raw_string) @string
(char_literal) @string

; String interpolation - capture the delimiters explicitly
(interpolation
  "${" @string.special
  "}" @string.special)

; Escape sequences
(escape_sequence) @string.escape

; Numbers
(integer) @number
(float) @number

; Booleans
[
  "true"
  "false"
] @constant.builtin

; Nil
(nil) @constant.builtin

; Built-in constants (matched by identifier text since they're not node types)
((identifier) @constant.builtin
  (#match? @constant.builtin "^(EXIT_SUCCESS|EXIT_FAILURE)$"))

; Blank identifier
((identifier) @variable.builtin
  (#eq? @variable.builtin "_"))

; Keywords
[
  "mut"
  "const"
  "do"
  "fn"
  "return"
  "if"
  "or"
  "elif"
  "otherwise"
  "else"
  "alias"
  "for"
  "for_each"
  "as_long_as"
  "while"
  "loop"
  "in"
  "not_in"
  "!in"
  "range"
  "import"
  "extern"
  "and"
  "using"
  "use"
  "struct"
  "enum"
  "new"
  "when"
  "switch"
  "is"
  "case"
  "default"
  "private"
  "ensure"
  "defer"
  "or_return"
  "or_panic"
  "or_default"
  "unsafe"
  "cast"
] @keyword

; Bitwise keyword operators
[
  "bit_and"
  "bit_or"
  "bit_xor"
  "bit_not"
  "bit_shift_left"
  "bit_shift_right"
] @keyword.operator

; Break and continue are named nodes
(break_statement) @keyword
(continue_statement) @keyword

; Types - builtin primitives (defined in grammar)
[
  "i8"
  "i16"
  "i32"
  "i64"
  "i128"
  "i256"
  "u8"
  "u16"
  "u32"
  "u64"
  "u128"
  "u256"
  "f32"
  "f64"
  "bool"
  "char"
  "string"
  "map"
  "func"
] @type.builtin

; Builtin types that are identifiers (runtime/stdlib types)
((identifier) @type.builtin
  (#match? @type.builtin "^(Database|Error|ErrorCode|SourceLocation|HttpResponse|HttpRequest|Thread|Mutex|Channel|Arena|SpinLock|Socket|Listener|Router|UUID|OpenFlag|Platform|Builder)$"))

; Type annotations - user defined types
(type (identifier) @type.builtin)

; Type in new() expressions
(new_expression
  type: (type (identifier) @type.builtin))

; Operators
[
  "+"
  "-"
  "*"
  "/"
  "%"
  "="
  "=="
  "!="
  "<"
  ">"
  "<="
  ">="
  "&&"
  "||"
  "!"
  "&"
  "^"
  "++"
  "--"
  "+="
  "-="
  "*="
  "/="
  "%="
  "->"
] @operator

; Punctuation - NOTE: } inside interpolation is handled above
[
  "("
  ")"
  "["
  "]"
  "{"
] @punctuation.bracket

; General } - but NOT inside interpolation (handled by query order)
(block "}" @punctuation.bracket)
(array_literal "}" @punctuation.bracket)
(map_literal "}" @punctuation.bracket)
(struct_literal "}" @punctuation.bracket)
(enum_declaration "}" @punctuation.bracket)
(struct_declaration "}" @punctuation.bracket)
(when_statement "}" @punctuation.bracket)

[
  ","
  "."
  ":"
  ";"
  "#"
] @punctuation.delimiter

; Attributes - use preprocessor/tag color (distinct from functions)
(attribute
  name: (identifier) @tag)

; Single-line attribute container: #[doc("x"), json]
(attribute_list
  (identifier) @tag)

; Import statements
(import_statement) @keyword
(import_and_use_statement) @keyword

; Import paths - stdlib modules with @ prefix
(import_path
  "@" @punctuation.special
  (identifier) @namespace)

; Import alias
(import_statement
  alias: (identifier) @namespace)

; Using statements (using std, using arrays)
(using_statement
  (identifier) @namespace)

; Function definitions - function color
(function_declaration
  name: (identifier) @function.definition)

; Struct function definitions (functions inside struct bodies)
(struct_declaration
  (function_declaration
    name: (identifier) @function.definition))

; Built-in function calls
(call_expression
  function: (identifier) @function.builtin
  (#match? @function.builtin "^(len|type_of|copy|error|exit|panic|assert|ref|flush|input|range|addr|println|print|eprintln|eprint|sleep_s|sleep_ms|sleep_ns|to_char|char_count|c_string|i128|u128|i256|u256|size_of|fields|system|raw|embed|here)$"))

; cast is a dedicated expression node - highlight keyword portion
(cast_expression
  "cast" @function.builtin)

; Function calls
(call_expression
  function: (identifier) @function.call)

; C interop calls: extern.puts(...)
(call_expression
  function: (extern_member
    property: (identifier) @function.call))

; Function references ()name
(func_ref
  (identifier) @function.call)

; Struct definitions - type color
(struct_declaration
  name: (identifier) @type.definition)

; Enum definitions - type color
(enum_declaration
  name: (identifier) @type.definition)

; Enum values - use constant color (distinct from types)
(enum_value
  (identifier) @constant)

; Variable declarations
(variable_declaration
  (identifier) @variable)

; Named return values
(named_return
  name: (identifier) @variable.parameter)

; Parameters
(parameter
  name: (identifier) @variable.parameter)

; Field declarations in structs - use property color
(field_declaration
  name: (identifier) @variable.member)

; Field access
(member_expression
  property: (identifier) @variable.member)

; Struct field initialization
(struct_field
  (identifier) @variable.member)

; Postfix operators
(postfix_expression
  ["++" "--" "^"] @operator)

; Pointer type caret
(pointer_type
  "^" @operator)

; Wildcard type
(wildcard_type) @type.builtin

; Type parameter annotation: do make(T <?>)
(type_parameter) @type.builtin

; Type alias declaration
(alias_declaration
  name: (identifier) @type.definition)

; Implicit enum selector: .NORTH
(implicit_selector
  variant: (identifier) @constant)

; Named argument at a call site: connect(host: "localhost")
(named_argument
  name: (identifier) @variable.parameter)

; Module-qualified type: models.Task
(qualified_type
  (identifier) @namespace
  .
  (identifier) @type.builtin)

; Function type: func(int, int) -> int
(func_type "func" @type.builtin)
