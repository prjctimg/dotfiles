-- ┌───────────────────────┐
-- │ Editing and buffers  │
-- └───────────────────────┘
--
-- Plugins that improve writing, formatting and buffer handling. None of them
-- has to be configured before the first buffer is drawn, so they all load on
-- `VeryLazy` -- the lazy.nvim equivalent of the `later()` helper the previous
-- `vim.pack` setup used, i.e. after the first screen draw.
--
-- Their keymaps and commands live in 'plugin/20_keymaps.lua'; `VeryLazy` fires
-- well before any of them can be pressed.

return {
  -- Incremental rename (inc-rename.nvim) =======================================
  --
  -- `vim.lsp.buf.rename()` applies the edit blind: you type a new name, it either
  -- works or it doesn't, and there is no way to review a rename that touches
  -- dozens of files before committing to it. 'inc-rename.nvim' instead re-uses
  -- Neovim's command-preview window to run the server's `textDocument/prepareRename`
  -- incrementally as you type, highlighting every reference that would change, so
  -- the rename is reviewed as a preview and only applied on <CR>.
  --
  -- That makes it safe for codebase-wide renames: the preview is the diff. Use
  -- `<Leader>lr` (or `<A-r>`) instead of a bare `vim.lsp.buf.rename()`; both are
  -- mapped in 'plugin/20_keymaps.lua'.
  --
  -- It needs a server that implements `textDocument/rename` and
  -- `textDocument/prepareRename`. With no such server the command reports that
  -- and does nothing, which is why the mappings fall back to the plain LSP
  -- rename when 'inc_rename' has no rename provider for the buffer.
  {
    'smjonas/inc-rename.nvim',
    event = 'VeryLazy',
    config = function()
      require('inc_rename').setup({
        -- 'Substitute' matches what Neovim highlights for `*`/`#`, so the preview
        -- reads as "these are the occurrences" rather than as pending changes.
        hl_group = 'Substitute',
        -- Typing an empty name would preview a delete-everything rename, so an
        -- empty buffer cancels the preview instead.
        preview_empty_name = false,
        -- Put the reference preview in the cmdwin rather than over the code.
        show_message = true,
        -- A preview is not a real rename; keep it out of ':history'.
        save_in_cmdline_history = false,
      })
    end,
  },

  -- Formatting =================================================================
  --
  -- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
  -- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
  -- They can be used to configure external programs, but it might become tedious.
  --
  -- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
  -- formatting setup.
  {
    'stevearc/conform.nvim',
    event = 'VeryLazy',
    config = function()
      -- See also:
      -- - `:h Conform`
      -- - `:h conform-options`
      -- - `:h conform-formatters`
      require('conform').setup({
        default_format_opts = {
          -- Allow formatting from LSP server if no dedicated formatter is available
          lsp_format = 'fallback',
        },
        -- Auto-format on save: runs the formatter above, falling back to attached
        -- LSP formatting when no dedicated formatter exists for a filetype. This
        -- covers every configured LSP (see 'vim.lsp.enable()' in 'lua/plugins/lsp.lua').
        -- Toggle with `<Leader>uf` (buffer) / `<Leader>uF` (global) -- see '20_keymaps.lua'.
        format_on_save = function(bufnr)
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          -- `gray fmt` type-checks before rewriting, so leave room for the
          -- compiler on large files or a cold start.
          return { timeout_ms = 5000, lsp_format = 'fallback' }
        end,
        -- Map of filetype to formatters
        -- Make sure that necessary CLI tool is available
        formatters_by_ft = {
          lua = { 'stylua' },
          rust = { 'rustfmt' },
          typescript = { 'deno_fmt' },
          javascript = { 'deno_fmt' },
          json = { 'deno_fmt' },
          markdown = { 'deno_fmt' },
          sh = { 'shfmt' },
          bash = { 'shfmt' },
          fish = { 'fish_indent' },
          -- `gray`, `wgsl`, `nix`, `python`, `css` and `html` have no dedicated
          -- formatter binary configured, so they are deliberately NOT listed
          -- here: a missing entry makes conform use the attached LSP instead
          -- (`lsp_format = 'fallback'` above). GrayLS implements
          -- `textDocument/formatting` by running `gray fmt` on a temporary
          -- copy of the buffer, which is why Gray formatting needs no custom
          -- conform formatter. `wgsl` is validated on write by `naga` (see the
          -- 'WGSL validation' section in 'lua/options.lua').
        },
      })
    end,
  },

  -- Yank history (yanky.nvim) =================================================
  --
  -- Ring-based yank history with no *mandatory* dependencies: sqlite (persistent
  -- storage), telescope/snacks (fancier pickers), nvim-treesitter (textobjects)
  -- and nvim-cmp are all optional and deliberately not used here. Yanks are
  -- recorded automatically via `TextYankPost`, so 'y'/'d'/'p' stay native. The
  -- ring history picker uses `vim.ui.select`, which this config routes through
  -- 'mini.pick'.
  {
    'gbprod/yanky.nvim',
    event = 'VeryLazy',
    config = function()
      require('yanky').setup({
        highlight = {
          on_put = true,
          on_yank = true,
          timer = 200,
        },
        ring = { history_length = 100 }, -- 'shada' storage (no sqlite dependency)
      })
    end,
  },

  -- Find and replace (grug-far.nvim) ==========================================
  --
  -- Interactive "find and replace" for the whole project, toggled from `<A-f>`
  -- in 'plugin/20_keymaps.lua'. Standalone: it does not depend on 'snacks.nvim';
  -- it only needs `ripgrep`.
  {
    'MagicDuck/grug-far.nvim',
    event = 'VeryLazy',
  },

  -- Snippets ===================================================================
  --
  -- Although 'mini.snippets' provides functionality to manage snippet files, it
  -- deliberately doesn't come with those.
  --
  -- The 'rafamadriz/friendly-snippets' is currently the largest collection of
  -- snippet files. They are organized in 'snippets/' directory (mostly) per language.
  -- 'mini.snippets' is designed to work with it as seamlessly as possible.
  -- See `:h MiniSnippets.gen_loader.from_lang()`.
  {
    'rafamadriz/friendly-snippets',
    event = 'VeryLazy',
  },
}
