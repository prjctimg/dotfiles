# tree-sitter-gray

Tree-sitter grammar for the [Grayscale programming language](https://github.com/grayscale-lang/Grayscale).

## Usage

This grammar is used by [GrayLS](https://github.com/grayscale-lang/grayls) for syntax highlighting in Zed.

## Updating the Grammar

### Prerequisites

```bash
npm install -g tree-sitter-cli
```

### Making Changes

1. Edit `grammar.js` to add/modify syntax rules

2. Regenerate the parser:
   ```bash
   tree-sitter generate
   ```

3. Test parsing (optional):
   ```bash
   tree-sitter parse path/to/file.gray
   ```

4. Commit and push:
   ```bash
   git add -A
   git commit -m "feat: description of change"
   git push
   ```

5. Update [GrayLS](https://github.com/grayscale-lang/grayls) with the new commit SHA

## Structure

| File | Purpose |
|------|---------|
| `grammar.js` | Grammar definition (edit this) |
| `src/parser.c` | Generated parser (don't edit) |
| `src/node-types.json` | Generated node types (don't edit) |

## Related

- [Grayscale Programming Language](https://github.com/grayscale-lang/Grayscale)
- [GrayLS](https://github.com/grayscale-lang/grayls) - Language server using this grammar
