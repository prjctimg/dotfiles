#include "tree_sitter/parser.h"

enum TokenType {
  SAME_LINE_OPERAND,
};

void *tree_sitter_gray_external_scanner_create(void) { return NULL; }

void tree_sitter_gray_external_scanner_destroy(void *payload) {}

unsigned tree_sitter_gray_external_scanner_serialize(void *payload, char *buffer) {
  return 0;
}

void tree_sitter_gray_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {}

static bool starts_operand(int32_t character) {
  return (character >= 'a' && character <= 'z') ||
         (character >= 'A' && character <= 'Z') ||
         (character >= '0' && character <= '9') ||
         character == '_' || character == '"' || character == '\'' ||
         character == '`' || character == '-' || character == '!' ||
         character == '(' || character == '.';
}

// Zero-width token that succeeds only when an expression begins on the same
// line as the preceding `or_return`, after spaces or tabs.
bool tree_sitter_gray_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) {
  if (!valid_symbols[SAME_LINE_OPERAND]) return false;

  while (lexer->lookahead == ' ' || lexer->lookahead == '\t') {
    lexer->advance(lexer, true);
  }

  if (!starts_operand(lexer->lookahead)) return false;

  lexer->result_symbol = SAME_LINE_OPERAND;
  return true;
}
