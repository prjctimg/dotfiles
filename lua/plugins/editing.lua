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
          return { timeout_ms = 500, lsp_format = 'fallback' }
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
          -- `wgsl`, `nix`, `python`, `css` and `html` have no formatter binary
          -- installed, so they are deliberately NOT listed here: a missing entry
          -- makes conform report "no formatters available" on every save. They
          -- format through the attached LSP instead (`lsp_format = 'fallback'`
          -- above), and `wgsl` is validated on write by `naga` (see the
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

  -- Dimming (tint.nvim) =======================================================
  --
  -- Desaturates and darkens the windows you are NOT focused in, so the split you
  -- are actually editing is the one that reads as "on". It is what LazyVim's
  -- `<Leader>uD` ("Toggle Dimming") does, expressed without 'snacks.nvim'.
  --
  -- 'tint.nvim' has no external dependencies at all -- it is three Lua files
  -- using only 'vim.api' -- and needs Neovim 0.8+ for the window highlight
  -- namespaces it relies on. It replaces the removed `windowhighlight` trick, so
  -- floating windows and terminals are excluded explicitly below rather than by
  -- losing the old 'Snacks' behaviour.
  {
    'levouh/tint.nvim',
    event = 'VeryLazy',
    config = function()
      local tint = require('tint')
      local xforms = require('tint.transforms')
      tint.setup({
        -- Negative darkens; a positive value would brighten instead. Keep the
        -- default's subtlety: heavy dimming makes an unfocused split look broken.
        tint = -45,
        saturation = 0.6,
        -- `transform_color` iterates this list with `ipairs`, so it has to be the
        -- list of functions, not the preset *name*. Two caveats make the preset
        -- unusable here: the shipped default is `transforms = nil`, and the preset
        -- is only resolved on a path `setup()` does not always take -- either way
        -- the first `toggle()` dies with "bad argument #1 to 'ipairs' (table
        -- expected, got ...)". Passing the two steps explicitly is what actually
        -- reaches the transform, and it makes the two numbers above self-documenting.
        transforms = {
          xforms.saturate(0.6),
          xforms.tint(-45),
        },
        tint_background_colors = true,
        -- Never dim the status line or the separators -- a grey `StatusLine` next
        -- to a tinted body reads as a rendering glitch, not as "unfocused".
        highlight_ignore_patterns = { 'WinSeparator', 'Status.*', 'NormalNC' },
        window_ignore_function = function(winid)
          local bufid = vim.api.nvim_win_get_buf(winid)
          -- Leave terminals and floats alone: dimming a terminal or this plugin's
          -- own float fights their own colours rather than receding.
          return vim.bo[bufid].buftype == 'terminal' or vim.api.nvim_win_get_config(winid).relative ~= ''
        end,
        -- This option has NO usable default: `tint.setup()` assigns the table it is
        -- handed straight to its own config (`__.user_config = user_config`) instead
        -- of merging with `default_config`, so every key left out stays nil and the
        -- first `toggle()` dies on "attempt to index field 'focus_change_events' (a
        -- nil value)". Both halves are therefore spelled out here.
        focus_change_events = {
          focus = { 'WinEnter' },
          unfocus = { 'WinLeave' },
        },
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
