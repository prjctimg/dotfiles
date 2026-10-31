-- ┌───────────────────────┐
-- │ Language server (LSP) │
-- └───────────────────────┘
--
-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of 'lua/plugins/editing.lua'.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.lsp` to see potential issues.

return {
  {
    'neovim/nvim-lspconfig',
    -- Same reasoning as the tree-sitter spec: `vim.lsp.enable()` has to run
    -- before the `FileType` of the first buffer, so the trigger is the read
    -- itself rather than a later startup event.
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- Grayscale ('gray') ======================================================
      --
      -- GrayLS is not in nvim-lspconfig's registry, so use the native
      -- `vim.lsp.config()` API here. The fork lives in '~/.local/share/grayls':
      -- prefer the `scriptc`-compiled `grayls` binary, and fall back to the
      -- Node build (`server.js`). Set `vim.g.grayls_bin` or
      -- `vim.g.grayls_server` to point somewhere else; setting
      -- `vim.g.grayls_server` forces the Node build (useful for debugging).
      --
      -- Advertised capabilities (probed from Neovim): completion (triggers `.`
      -- and `@`), hover, go-to-definition, document symbols, references,
      -- prepare-rename/rename, document formatting, and push diagnostics
      -- through `gray check`. It has no code actions, semantic tokens, or
      -- folding; folds/indentation come from tree-sitter. Formatting runs
      -- `gray fmt` inside GrayLS, and conform reaches it through its LSP
      -- fallback, so `.gray` uses the same formatter as the CLI.
      --
      -- `gray` must be on PATH for diagnostics and formatting; the other
      -- features work without it.
      local grayls_dir = vim.fs.joinpath(vim.fn.expand('~/.local/share'), 'grayls')
      local grayls_bin = vim.g.grayls_bin or vim.fs.joinpath(grayls_dir, 'grayls')
      local grayls_server = vim.g.grayls_server or vim.fs.joinpath(grayls_dir, 'server.js')

      local grayls_cmd
      if vim.g.grayls_server then
        if vim.fn.executable('node') == 1 and vim.uv.fs_stat(grayls_server) then
          grayls_cmd = { 'node', grayls_server, '--stdio' }
        end
      elseif vim.fn.executable(grayls_bin) == 1 then
        grayls_cmd = { grayls_bin, '--stdio' }
      elseif vim.fn.executable('node') == 1 and vim.uv.fs_stat(grayls_server) then
        grayls_cmd = { 'node', grayls_server, '--stdio' }
      end

      if grayls_cmd then
        vim.lsp.config('grayls', {
          cmd = grayls_cmd,
          filetypes = { 'gray' },
          root_markers = { 'gray.toml', '.git' },
          -- `workspace_required` defaults to false, so GrayLS also attaches to
          -- single files outside a project.
        })
        vim.lsp.enable('grayls')
      end

      -- Use `:h vim.lsp.enable()` to automatically enable language server based on
      -- the rules provided by 'nvim-lspconfig'.
      -- Use `:h vim.lsp.config()` or 'after/lsp/' directory to configure servers.
      vim.lsp.enable({
        'rust_analyzer', -- Rust (via rustup component)
        'vtsls', -- TypeScript / JavaScript (vtsls, Node projects)
        'denols', -- TypeScript / JavaScript (Deno projects)
        'lua_ls', -- Lua (lua-language-server)
        'markdown_oxide', -- Markdown (markdown-oxide, Rust)
        'asm_lsp', -- Assembly (asm-lsp)
        'bashls', -- Shell (bash-language-server via npm)
        'fish_lsp', -- fish shell (fish-language-server via npm, Node-based)
        -- Shaders, web, scripting and packaging. Each entry resolves its `cmd`
        -- lazily, so a server with no binary installed is simply skipped instead of
        -- erroring on startup. Install the binary and the server attaches with no
        -- further config change:
        --   wgsl_analyzer  -- release binary from wgsl-analyzer/wgsl-analyzer
        --                     (or: cargo install --git ... wgsl-analyzer)  (WGSL)
        --   basedpyright  -- pipx/uv/npm  (Python; also provides py.venv handling)
        --   nixd           -- nix profile install nixd     (Nix)
        --   cssls / html  -- npm i -g vscode-langservers-extracted
        'wgsl_analyzer',
        'basedpyright',
        'nixd',
        'cssls',
        'html',
      })

      -- Pyright needs the project environment to resolve imports; point it at the
      -- nearest virtualenv instead of the system Python.
      vim.lsp.config('basedpyright', {
        settings = {
          python = {
            analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true },
          },
        },
      })
    end,
  },
}
