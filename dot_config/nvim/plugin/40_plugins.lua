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
  local languages = {
    -- Bundled with Neovim
    'lua',
    'vimdoc',
    'markdown',
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

  -- emoji.nvim
  pcall(function() require('emoji').setup({ enable_cmp_integration = false, ui_select = true }) end)

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
