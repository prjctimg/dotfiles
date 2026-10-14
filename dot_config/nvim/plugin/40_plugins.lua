-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages
local add = vim.pack.add
local now_if_args, later = Config.now_if_args, Config.later

-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
--   NOTE: It requires third party software to build and install parsers.
--   See the link for more info in "Requirements" section of the MiniMax README.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).
now_if_args(function()
  -- Define hook to update tree-sitter parsers after plugin is updated
  local ts_update = function() vim.cmd('TSUpdate') end
  Config.on_packchanged('nvim-treesitter', { 'update' }, ts_update, ':TSUpdate')

  add({
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
  })

  -- Define languages which will have parsers installed and auto enabled
  -- After changing this, restart Neovim once to install necessary parsers. Wait
  -- for the installation to finish before opening a file for added language(s).
  --
  -- NOTE: a parser shipping with Neovim still has to be listed here. Tree-sitter
  -- is only *started* by the 'FileType' autocmd below, so a missing entry means
  -- no highlighting even when `parser/<lang>.so` exists ('wgsl' was exactly this:
  -- bundled parser, never started). Neovim 0.12 bundles: c, lua, markdown,
  -- markdown_inline, query, vim, vimdoc, wgsl, and all of the ones below.
  local languages = {
    -- Bundled with Neovim
    'lua',
    'vimdoc',
    'markdown',
    'markdown_inline',
    'query',
    'wgsl',
    -- Personal language set: TS/JS, Rust, Assembly, shell/fish, configs
    'typescript',
    'tsx',
    'javascript',
    'bash',
    'fish',
    'rust',
    'asm',
    'json',
    'toml',
    'yaml',
    -- Web / styling / scripting / packaging used across the workspace
    'css',
    'html',
    'python',
    'nix',
    'git_config',
    'gitignore',
    'diff',
    'regex',
  }
  local isnt_installed = function(lang)
    return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
  end
  local to_install = vim.tbl_filter(isnt_installed, languages)
  if #to_install > 0 then require('nvim-treesitter').install(to_install) end

  -- Parse 'mdx' files (Markdown + JSX) with the built-in 'markdown' parser so
  -- highlighting, render-markdown, and image.nvim all work there.
  vim.treesitter.language.register('markdown', 'mdx')

  -- Enable tree-sitter after opening a file for a target language
  local filetypes = {}
  for _, lang in ipairs(languages) do
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
      table.insert(filetypes, ft)
    end
  end
  local ts_start = function(ev) vim.treesitter.start(ev.buf) end
  Config.new_autocmd('FileType', filetypes, ts_start, 'Start tree-sitter')
end)

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.lsp` to see potential issues.
now_if_args(function()
  add({ 'https://github.com/neovim/nvim-lspconfig' })

  -- Use `:h vim.lsp.enable()` to automatically enable language server based on
  -- the rules provided by 'nvim-lspconfig'.
  -- Use `:h vim.lsp.config()` or 'after/lsp/' directory to configure servers.
  vim.lsp.enable({
    'rust_analyzer',   -- Rust (via rustup component)
    'vtsls',           -- TypeScript / JavaScript (vtsls, Node projects)
    'denols',          -- TypeScript / JavaScript (Deno projects)
    'lua_ls',          -- Lua (lua-language-server)
    'markdown_oxide',  -- Markdown (markdown-oxide, Rust)
    'asm_lsp',         -- Assembly (asm-lsp)
    'bashls',          -- Shell (bash-language-server via npm)
    'fish_lsp',        -- fish shell (fish-lsp via npm, Node-based)
    -- Shaders, web, scripting and packaging. Each entry resolves its `cmd`
    -- lazily, so a server with no binary installed is simply skipped instead of
    -- erroring on startup. Install the binary and the server attaches with no
    -- further config change:
    --   wgsl_analyzer  -- cargo install wgsl_analyzer   (WGSL)
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
end)

-- Incremental rename (inc-rename.nvim) =======================================

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
-- and does nothing, which is why the mappings below fall back to the plain LSP
-- rename when 'inc_rename' has no rename provider for the buffer.
later(function()
  add({ 'https://github.com/smjonas/inc-rename.nvim' })
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
end)

-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
later(function()
  add({ 'https://github.com/stevearc/conform.nvim' })

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
    -- covers every configured LSP (see 'vim.lsp.enable()' above). Toggle with
    -- `<Leader>uf` (buffer) / `<Leader>uF` (global) — see '20_keymaps.lua'.
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
      -- 'WGSL validation' section in 'plugin/10_options.lua').
    },
  })
end)

-- Yank history (yanky.nvim) ===================================================
--
-- Ring-based yank history with no *mandatory* dependencies: sqlite (persistent
-- storage), telescope/snacks (fancier pickers), nvim-treesitter (textobjects)
-- and nvim-cmp are all optional and deliberately not used here. Yanks are
-- recorded automatically via `TextYankPost`, so 'y'/'d'/'p' stay native. The
-- ring history picker uses `vim.ui.select`, which this config routes through
-- 'mini.pick'.
later(function()
  add({ 'https://github.com/gbprod/yanky.nvim' })
  require('yanky').setup({
    highlight = {
      on_put = true,
      on_yank = true,
      timer = 200,
    },
    ring = { history_length = 100 }, -- 'shada' storage (no sqlite dependency)
  })
end)

-- Find and replace (grug-far.nvim) ===========================================
--
-- Interactive "find and replace" for the whole project, toggled from `<A-f>`
-- in 'plugin/20_keymaps.lua'. Standalone: it does not depend on 'snacks.nvim';
-- it only needs `ripgrep`.
later(function() add({ 'https://github.com/MagicDuck/grug-far.nvim' }) end)

-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function() add({ 'https://github.com/rafamadriz/friendly-snippets' }) end)

-- Personal plugins ===========================================================
--
-- Ported from the previous LazyVim setup. Everything that depended on
-- 'snacks.nvim' was dropped; the rest is kept as-is.

-- MDX (Markdown + JSX) gets its own filetype and is parsed with the 'markdown'
-- tree-sitter parser (registered above), so render-markdown and image.nvim work
-- in '*.mdx' files too.
vim.filetype.add({ extension = { mdx = 'mdx' } })

-- render-markdown.nvim: rendered Markdown/MDX in the buffer itself
now_if_args(function()
  add({ 'https://github.com/MeanderingProgrammer/render-markdown.nvim' })
  require('render-markdown').setup({
    enabled = true,
    render_modes = { 'n', 'i', 'c', 't', 'x' },
    debounce = 100,
  })
end)

-- image.nvim: inline image rendering in markdown/mdx. Uses the 'kitty' backend
-- (Ghostty implements the Kitty graphics protocol) and needs ImageMagick.
now_if_args(function()
  add({ 'https://github.com/3rd/image.nvim' })
  pcall(function()
    require('image').setup({
      backend = 'kitty',
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = true, -- hide images while typing to avoid flicker
          only_render_image_at_cursor = false, -- render all images in the viewport
          filetypes = { 'markdown', 'vimwiki', 'mdx' },
        },
      },
    })
  end)
end)

later(function()
  add({
    'https://github.com/prjctimg/stoic.nvim',
    'https://github.com/prjctimg/p5.nvim',
    'https://github.com/2kabhishek/nerdy.nvim',
    'https://github.com/allaman/emoji.nvim',
    'https://github.com/epwalsh/pomo.nvim',
  })

  -- stoic.nvim (needs explicit setup; was `opts = {}` in lazy.nvim)
  pcall(function() require('stoic').setup({}) end)

  -- emoji.nvim (vim.pack installs plugins under stdpath('data')/site/pack/core/opt,
  -- NOT the lazy.nvim layout the plugin's defaults assume — point `plugin_path`
  -- at the real install location or `:Emoji` opens an empty picker)
  pcall(function()
    require('emoji').setup({
      enable_cmp_integration = false,
      ui_select = true,
      plugin_path = vim.fn.stdpath('data') .. '/site/pack/core/opt/',
    })
  end)

  -- nerdy.nvim (glyph picker; may need a picker integration at runtime)
  pcall(function() require('nerdy').setup({ max_recents = 30, add_default_keybindings = true }) end)

  -- pomo.nvim (unchanged from the previous config)
  require('pomo').setup({
    update_interval = 1000,
    notifiers = {
      { name = 'Default', opts = { sticky = false, title_icon = '󱎫', text_icon = '󰄉' } },
      { name = 'System' },
    },
    timers = { Break = { { name = 'System' } } },
    sessions = {
      pomodoro = {
        { name = 'Work', duration = '25m' },
        { name = 'Short Break', duration = '5m' },
        { name = 'Work', duration = '25m' },
        { name = 'Short Break', duration = '5m' },
        { name = 'Work', duration = '25m' },
        { name = 'Long Break', duration = '15m' },
      },
    },
  })
end)

-- gtm.nvim (music player UI; talks to the `gtmd` daemon over a Unix socket).
-- The plugin's own 'plugin/gtm.lua' loader auto-setups with defaults whenever
-- lazy.nvim is absent. Opt out by setting `vim.g.loaded_gtm` BEFORE the plugin
-- loads, so the explicit setup below is the only one. (`gtm.setup` is
-- idempotent, so even a load-order edge case ends with one registration.)
later(function()
  vim.g.loaded_gtm = true
  add({ 'https://github.com/prjctimg/gtm.nvim' })

  local ok, gtm = pcall(require, 'gtm')
  if ok then
    gtm.setup({
      statusline_format = 'compact',
      theme = { reactive = true, intensity = 0.22, scope = 'global' },
    })
  end
end)

-- Honorable mentions =========================================================

-- 'mason-org/mason.nvim' (a.k.a. "Mason") is a great tool (package manager) for
-- installing external language servers, formatters, and linters. It provides
-- a unified interface for installing, updating, and deleting such programs.
--
-- The caveat is that these programs will be set up to be mostly used inside Neovim.
-- If you need them to work elsewhere, consider using other package managers.
--
-- You can use it like so:
-- now_if_args(function()
--   add({ 'https://github.com/mason-org/mason.nvim' })
--   require('mason').setup()
-- end)

-- Beautiful, usable, well maintained color schemes outside of 'mini.nvim' and
-- have full support of its highlight groups. Use if you don't like 'miniwinter'
-- enabled in 'plugin/30_mini.lua' or other suggested 'mini.hues' based ones.
-- Config.now(function()
--  -- Install only those that you need
--  add({
--    'https://github.com/sainnhe/everforest',
--    'https://github.com/Shatur/neovim-ayu',
--    'https://github.com/ellisonleao/gruvbox.nvim',
--  })
--
--   -- Enable only one
--   vim.cmd('color everforest')
-- end)
