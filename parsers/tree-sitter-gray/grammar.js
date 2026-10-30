module.exports = grammar({
  name: 'gray',

  extras: $ => [
    /\s/,
    $.comment,
    $.block_comment,
  ],

  word: $ => $.identifier,

  externals: $ => [
    $._same_line_operand,
  ],

  conflicts: $ => [
    [$.struct_literal, $._expression],
    [$.variable_declaration],
    [$.variable_declaration, $._expression],
    [$.block, $.array_literal],
    [$.expression_statement, $.array_literal],
    [$.named_return, $.type],
    [$.or_return_expression],
  ],

  rules: {
    source_file: $ => repeat(choice($._statement, ';')),

    _statement: $ => choice(
      $.import_statement,
      $.using_statement,
      $.import_and_use_statement,
      $.variable_declaration,
      $.alias_declaration,
      $.function_declaration,
      $.struct_declaration,
      $.enum_declaration,
      $.if_statement,
      $.for_statement,
      $.for_each_statement,
      $.as_long_as_statement,
      $.loop_statement,
      $.when_statement,
      $.return_statement,
      $.break_statement,
      $.continue_statement,
      $.ensure_statement,
      $.unsafe_block,
      $.assignment_statement,
      $.expression_statement,
      $.block,
    ),

    // Import statements. `extern import "stdio.h"` imports a C header.
    import_statement: $ => seq(
      optional('extern'),
      'import',
      $._import_item,
      repeat(seq(',', $._import_item)),
    ),

    // A path may carry its own alias: import m @math, str@strings
    _import_item: $ => seq(
      optional(field('alias', $.identifier)),
      $.import_path,
    ),

    import_path: $ => choice(
      seq('@', $.identifier),           // @std
      seq('"', /[^"]+/, '"'),           // "path/to/module" or "header.h"
    ),

    using_statement: $ => seq(
      'using',
      $.identifier,
      repeat(seq(',', $.identifier)),
    ),

    import_and_use_statement: $ => seq(
      'import',
      'and',
      'use',
      $._import_item,
      repeat(seq(',', $._import_item)),
    ),

    // Type alias
    alias_declaration: $ => seq(
      optional('private'),
      'alias',
      field('name', $.identifier),
      '=',
      field('type', $.type),
    ),

    // Variable declaration. `mut` is optional — variables are mutable by
    // default. The keyword-less form requires a type annotation so it cannot be
    // confused with a plain assignment.
    variable_declaration: $ => seq(
      repeat($._attribute),
      optional('private'),
      choice(
        seq(
          choice('mut', 'const'),
          $.identifier,
          optional($.type),
          repeat(seq(',', $.identifier, optional($.type))),
        ),
        seq(
          $.identifier,
          choice(
            seq($.type, repeat(seq(',', $.identifier, optional($.type)))),
            seq(
              repeat1(seq(',', $.identifier)),
              $.type,
              repeat(seq(',', $.identifier, optional($.type))),
            ),
          ),
        ),
      ),
      optional(seq('=', $._expression, repeat(seq(',', $._expression)))),
    ),

    // Function declaration
    function_declaration: $ => seq(
      repeat($._attribute),
      optional('private'),
      optional('unsafe'),
      choice('do', 'fn'),
      field('name', $.identifier),
      '(',
      optional($.parameter_list),
      ')',
      optional(seq('->', $.return_types)),
      $.block,
    ),

    parameter_list: $ => seq(
      $.parameter,
      repeat(seq(',', $.parameter)),
    ),

    parameter: $ => choice(
      seq(
        optional('&'),
        field('name', $.identifier),
        repeat(seq(',', optional('&'), field('name', $.identifier))),
        field('type', choice($.type, $.type_parameter)),
        optional(seq('=', $._expression)),
      ),
      // Type inferred from the default: do move(dir = Direction.NORTH)
      seq(field('name', $.identifier), '=', $._expression),
    ),

    // Type parameter annotation: do make(T <?>)
    type_parameter: $ => seq('<', '?', '>'),

    return_types: $ => choice(
      $.type,
      seq('(', $.named_return, repeat(seq(',', $.named_return)), ')'),
    ),

    named_return: $ => seq(
      optional(seq(field('name', $.identifier), repeat(seq(',', field('name', $.identifier))))),
      field('type', $.type),
    ),

    // Struct declaration
    struct_declaration: $ => seq(
      repeat($._attribute),
      optional('private'),
      'const',
      field('name', $.identifier),
      'struct',
      '{',
      repeat(choice($.field_declaration, $.function_declaration, ';')),
      '}',
    ),

    // A raw string after the type is a field tag: name string `json:"Name"`
    field_declaration: $ => seq(
      field('name', $.identifier),
      repeat(seq(',', field('name', $.identifier))),
      field('type', $.type),
      optional(field('tag', $.raw_string)),
      optional(seq('=', field('default', $._expression))),
      optional(','),
    ),

    // Enum declaration
    enum_declaration: $ => seq(
      repeat($._attribute),
      optional('private'),
      'const',
      field('name', $.identifier),
      'enum',
      '{',
      repeat(choice($.enum_value, ';')),
      '}',
    ),

    enum_value: $ => seq(
      $.identifier,
      optional(choice(
        $.variant_payload,
        seq('=', $._expression),
      )),
      optional(','),
    ),

    // Tagged enum payload: Circle(float), Rect(float, float)
    variant_payload: $ => seq(
      '(',
      $.type,
      repeat(seq(',', $.type)),
      ')',
    ),

    _attribute: $ => choice($.attribute, $.attribute_list),

    attribute: $ => seq(
      '#',
      field('name', $.identifier),
      optional(seq('(', $._expression, ')')),
    ),

    // Single-line container form: #[doc("x"), json, deprecated("use y")]
    attribute_list: $ => seq(
      '#',
      '[',
      $._attribute_item,
      repeat(seq(',', $._attribute_item)),
      ']',
    ),

    _attribute_item: $ => seq(
      field('name', $.identifier),
      optional(seq('(', $._expression, ')')),
    ),

    // Control flow
    if_statement: $ => seq(
      'if',
      $._expression,
      $.block,
      repeat($.or_clause),
      optional($.otherwise_clause),
    ),

    or_clause: $ => seq(
      choice('or', 'elif'),
      $._expression,
      $.block,
    ),

    otherwise_clause: $ => seq(
      choice('otherwise', 'else'),
      $.block,
    ),

    for_statement: $ => choice(
      prec(2, seq(
        'for',
        optional('('),
        $.identifier,
        optional($.type),
        'in',
        $._expression,
        optional(')'),
        $.block,
      )),
      // Condition form: for i < 5 { }
      prec(1, seq('for', $._expression, $.block)),
    ),

    for_each_statement: $ => seq(
      'for_each',
      optional('('),
      $.identifier,
      optional(seq(',', $.identifier)),
      optional($.type),
      'in',
      $._expression,
      optional(')'),
      $.block,
    ),

    as_long_as_statement: $ => seq(
      choice('as_long_as', 'while'),
      $._expression,
      $.block,
    ),

    loop_statement: $ => seq(
      'loop',
      $.block,
    ),

    // When statement (switch/match equivalent)
    when_statement: $ => seq(
      repeat($._attribute),
      choice('when', 'switch'),
      $._expression,
      '{',
      repeat($.is_clause),
      optional($.default_clause),
      '}',
    ),

    is_clause: $ => seq(
      choice('is', 'case'),
      $._expression,
      repeat(seq(',', $._expression)),
      $.block,
    ),

    default_clause: $ => seq(
      'default',
      $.block,
    ),

    return_statement: $ => prec.right(seq(
      'return',
      optional(seq($._expression, repeat(seq(',', $._expression)))),
    )),

    break_statement: $ => 'break',

    continue_statement: $ => 'continue',

    // Ensure statement (runs on function exit). `defer` is an alias.
    ensure_statement: $ => prec(11, seq(
      choice('ensure', 'defer'),
      $.call_expression,
    )),

    // Unsafe block: raw(), mem, threads, and extern calls live inside it
    unsafe_block: $ => seq('unsafe', $.block),

    // Assignment
    assignment_statement: $ => seq(
      $._expression,
      repeat(seq(',', $._expression)),
      choice('=', '+=', '-=', '*=', '/=', '%='),
      $._expression,
      repeat(seq(',', $._expression)),
    ),

    expression_statement: $ => $._expression,

    block: $ => seq(
      '{',
      repeat(choice($._statement, ';')),
      '}',
    ),

    // Expressions
    _expression: $ => choice(
      $.identifier,
      $.number,
      $.string,
      $.raw_string,
      $.char_literal,
      $.boolean,
      $.nil,
      $.array_literal,
      $.map_literal,
      $.struct_literal,
      $.call_expression,
      $.cast_expression,
      $.member_expression,
      $.implicit_selector,
      $.index_expression,
      $.unary_expression,
      $.postfix_expression,
      $.binary_expression,
      $.grouped_expression,
      $.new_expression,
      $.extern_member,
      $.range_expression,
      $.or_return_expression,
      $.or_panic_expression,
      $.or_default_expression,
      $.func_ref,
    ),

    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    number: $ => choice(
      $.integer,
      $.float,
    ),

    integer: $ => choice(
      /[0-9][0-9_]*/,
      /0x[0-9a-fA-F_]+/,
      /0b[01_]+/,
      /0o[0-7_]+/,
    ),

    float: $ => choice(
      /[0-9][0-9_]*\.[0-9][0-9_]*([eE][+-]?[0-9][0-9_]*)?/,
      /[0-9][0-9_]*[eE][+-]?[0-9][0-9_]*/,
    ),

    string: $ => seq(
      '"',
      repeat(choice(
        $.string_content,
        $.escape_sequence,
        $.interpolation,
        token.immediate('$'),
      )),
      '"',
    ),

    string_content: $ => token.immediate(prec(1, /[^"\\$]+/)),

    escape_sequence: $ => token.immediate(/\\[nrtabfv\\'"0$]|\\x[0-9a-fA-F]{2}|\\u\{[0-9a-fA-F]{1,6}\}/),

    interpolation: $ => seq(
      '${',
      $._expression,
      '}',
    ),

    raw_string: $ => seq(
      '`',
      token.immediate(prec(1, /[^`]*/)),
      '`',
    ),

    char_literal: $ => seq(
      "'",
      choice(/[^'\\]/, $.escape_sequence),
      "'",
    ),

    boolean: $ => choice('true', 'false'),

    nil: $ => 'nil',

    array_literal: $ => seq(
      '{',
      optional(seq($._expression, repeat(seq(',', $._expression)))),
      '}',
    ),

    // {:} is the empty map literal; non-empty maps have key:value entries
    map_literal: $ => seq(
      '{',
      choice(
        seq($.map_entry, repeat(seq(',', $.map_entry))),
        ':',
      ),
      '}',
    ),

    map_entry: $ => seq(
      $._expression,
      ':',
      $._expression,
    ),

    struct_literal: $ => prec.dynamic(1, seq(
      choice($.identifier, $.member_expression),
      '{',
      optional(seq($.struct_field, repeat(seq(',', $.struct_field)))),
      '}',
    )),

    struct_field: $ => seq(
      $.identifier,
      ':',
      $._expression,
    ),

    call_expression: $ => prec(11, seq(
      field('function', $._expression),
      '(',
      optional(seq($._argument, repeat(seq(',', $._argument)))),
      ')',
    )),

    _argument: $ => choice(
      $.named_argument,
      $._expression,
      // Type arguments for size_of() and friends; these forms are not
      // otherwise valid expressions, so they cannot be ambiguous.
      $.pointer_type,
      $.array_type,
      $.map_type,
    ),

    // Named argument at a call site: connect(host: "localhost")
    named_argument: $ => seq(
      field('name', $.identifier),
      ':',
      field('value', $._expression),
    ),

    // cast(value, type) or cast(value, [type])
    cast_expression: $ => prec(11, seq(
      'cast',
      '(',
      $._expression,
      ',',
      choice($.array_type, $.type),
      ')',
    )),

    // Implicit enum selector: .NORTH, where the enum type is known from context
    implicit_selector: $ => prec(12, seq(
      '.',
      field('variant', $.identifier),
    )),

    member_expression: $ => prec.left(12, seq(
      $._expression,
      '.',
      field('property', $.identifier),
    )),

    index_expression: $ => prec.left(12, seq(
      $._expression,
      '[',
      $._expression,
      ']',
    )),

    unary_expression: $ => prec.right(10, seq(
      choice('-', '!', 'bit_not'),
      $._expression,
    )),

    postfix_expression: $ => prec.left(13, seq(
      $._expression,
      choice('++', '--', '^'),
    )),

    // Precedence levels match the Grayscale parser (PREC_OR=1 through PREC_PRODUCT=9)
    binary_expression: $ => choice(
      prec.left(1, seq($._expression, '||',                                    $._expression)),
      prec.left(2, seq($._expression, '&&',                                    $._expression)),
      prec.left(3, seq($._expression, choice('==', '!='),                      $._expression)),
      prec.left(4, seq($._expression, choice('bit_and', 'bit_or', 'bit_xor'), $._expression)),
      prec.left(5, seq($._expression, choice('<', '>', '<=', '>='),            $._expression)),
      prec.left(6, seq($._expression, choice('in', 'not_in', '!in'),           $._expression)),
      prec.left(7, seq($._expression, choice('bit_shift_left', 'bit_shift_right'), $._expression)),
      prec.left(8, seq($._expression, choice('+', '-'),                        $._expression)),
      prec.left(9, seq($._expression, choice('*', '/', '%'),                   $._expression)),
    ),

    grouped_expression: $ => seq('(', $._expression, ')'),

    new_expression: $ => prec.right(seq(
      'new',
      '(',
      field('type', $.type),
      ')',
      optional(seq('{', optional(seq($.struct_field, repeat(seq(',', $.struct_field)))), '}')),
    )),

    range_expression: $ => seq(
      'range',
      '(',
      $._expression,
      optional(seq(',', $._expression)),
      optional(seq(',', $._expression)),
      ')',
    ),

    // Fallback values must start on the same line as `or_return`; the external
    // scanner decides that, since a following-line statement is not a fallback.
    or_return_expression: $ => prec.right(seq(
      $._expression,
      'or_return',
      optional(seq(
        $._same_line_operand,
        $._expression,
        repeat(prec.dynamic(1, seq(',', $._expression))),
      )),
    )),

    // An optional panic message must start on the same line as `or_panic`.
    or_panic_expression: $ => prec.right(seq(
      $.call_expression,
      'or_panic',
      optional(seq($._same_line_operand, $._expression)),
    )),

    // Fallback values are required and start on the same line as `or_default`.
    or_default_expression: $ => prec.right(seq(
      $.call_expression,
      'or_default',
      $._same_line_operand,
      $._expression,
      repeat(prec.dynamic(1, seq(',', $._expression))),
    )),

    // C interop access: extern.puts, extern.EOF
    extern_member: $ => prec.left(12, seq(
      'extern',
      '.',
      field('property', $.identifier),
    )),

    func_ref: $ => seq(
      '(',
      ')',
      $.identifier,
    ),

    // Types
    type: $ => choice(
      $.primitive_type,
      $.func_type,
      $.array_type,
      $.map_type,
      $.pointer_type,
      $.wildcard_type,
      $.qualified_type,
      $.identifier,  // user-defined types
    ),

    // Module-qualified type: models.Task, types.Status
    qualified_type: $ => prec(2, seq($.identifier, '.', $.identifier)),

    wildcard_type: $ => '?',

    primitive_type: $ => choice(
      'i8', 'i16', 'i32', 'i64', 'i128', 'i256',
      'u8', 'u16', 'u32', 'u64', 'u128', 'u256',
      'f32', 'f64',
      'bool', 'char', 'string',
    ),

    // Function type: func, func(int, int) -> int, func(&int)
    func_type: $ => prec.right(seq(
      'func',
      optional(seq(
        '(',
        optional(seq($._func_param_type, repeat(seq(',', $._func_param_type)))),
        ')',
      )),
      optional(seq('->', choice(
        $.type,
        seq('(', $.type, repeat(seq(',', $.type)), ')'),
      ))),
    )),

    _func_param_type: $ => seq(optional('&'), $.type),

    array_type: $ => seq(
      '[',
      $.type,
      optional(seq(',', choice($.integer, $.identifier))),
      ']',
    ),

    // The `map` keyword is optional in type position: [K:V] == map[K:V]
    map_type: $ => seq(
      optional('map'),
      '[',
      $.type,
      ':',
      $.type,
      ']',
    ),

    pointer_type: $ => seq(
      '^',
      $.type,
    ),

    // Comments
    comment: $ => /\/\/[^\n]*/,

    block_comment: $ => /\/\*[^*]*\*+([^\/*][^*]*\*+)*\//,
  },
});
