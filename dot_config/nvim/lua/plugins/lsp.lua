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
      -- 'mini.files' reads LSP file-operation filters directly when it applies
      -- create/delete/rename actions. Some servers send `null` for optional
      -- fields (for example markdown-oxide sends `scheme = null`), which reaches
      -- Lua as `vim.NIL`. mini.files' filter builder then tries to concatenate
      -- it and errors *after* the filesystem action has already succeeded, so
      -- the next synchronization reports "Target path already exists" even
      -- though the rename/move worked. Normalize the filters when a client
      -- attaches: drop `vim.NIL` values and use an empty filter list when the
      -- server omitted `filters` entirely.
      local sanitize_file_operations = function(client)
        local workspace = client.server_capabilities and client.server_capabilities.workspace
        local file_operations = workspace and workspace.fileOperations
        if type(file_operations) ~= 'table' then
          return
        end

        -- Replace vim.NIL (userdata representing JSON null from LSP servers)
        -- with Lua nil so mini.files never sees a userdata where it expects a
        -- string or table.  Also strip any nil values from filter tables.
        local function strip_nil(value)
          if value == vim.NIL then
            return nil
          end
          if type(value) ~= 'table' then
            return value
          end
          local result = {}
          for key, item in pairs(value) do
            local cleaned = strip_nil(item)
            if cleaned ~= nil then
              result[key] = cleaned
            end
          end
          return result
        end

        for _, options in pairs(file_operations) do
          if type(options) == 'table' then
            if type(options.filters) ~= 'table' then
              options.filters = {}
            else
              options.filters = strip_nil(options.filters)
            end
          end
        end
      end

      Config.new_autocmd('LspAttach', nil, function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client ~= nil then
          sanitize_file_operations(client)

          -- Enable inlay hints by default when supported so they are visible in action.
          if client.supports_method and client:supports_method('textDocument/inlayHint', { bufnr = ev.buf }) then
            pcall(vim.lsp.inlay_hint.enable, true, { bufnr = ev.buf })
          elseif vim.lsp.inlay_hint and client.server_capabilities and client.server_capabilities.inlayHintProvider then
            pcall(vim.lsp.inlay_hint.enable, true, { bufnr = ev.buf })
          end
        end
      end, 'Normalize LSP file-operation filters and enable inlay hints')

      -- Also cover clients that attached before this spec was loaded.
      for _, client in ipairs(vim.lsp.get_clients()) do
        sanitize_file_operations(client)
      end

      -- Grayscale ('gray') ======================================================
      --
      -- GrayLS is not in nvim-lspconfig's registry, so use the native
      -- `vim.lsp.config()` API here. The fork lives in '~/.local/share/grayls':
      -- prefer the `scriptc`-compiled `grayls` binary, and fall back to the
      -- Node build (`server.js`). Set `vim.g.grayls_bin` or
      -- `vim.g.grayls_server` to point somewhere else; setting
      -- `vim.g.grayls_server` forces the Node build (useful for debugging).
      --
      -- Advertised capabilities: completion (triggers `.` and `@`), hover,
      -- go-to-definition, document symbols, references, prepare-rename/rename,
      -- document formatting, signature help, inlay hints, semantic tokens,
      -- code actions, workspace symbols, and push diagnostics via `gray check`.
      -- Folding/indentation come from tree-sitter. Formatting runs `gray fmt`
      -- inside GrayLS (and conform can fall back to LSP formatting).
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
        'ols', -- Odin (ols)
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

      -- Rust: enable auto-import suggestions/completions for unresolved symbols.
      vim.lsp.config('rust_analyzer', {
        settings = {
          ['rust-analyzer'] = {
            completion = {
              autoimport = { enable = true },
              postfix = { enable = true },
            },
            imports = {
              granularity = { group = 'module' },
              prefix = 'self',
            },
          },
        },
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
