-- ┌─────────────┐
-- │ Tree-sitter │
-- └─────────────┘
--
-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
--   NOTE: It requires third party software to build and install parsers.
--   See the link for more info in "Requirements" section in MiniMax README.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).

-- Languages which have parsers installed and auto enabled. After changing this,
-- restart Neovim once to install the necessary parsers (see the `VimEnter` hook
-- below); wait for the installation to finish before opening a file that uses an
-- added language.
--
-- NOTE: a parser shipping with Neovim still has to be listed here. Tree-sitter is
-- only *started* by the `FileType` autocmd below, so a missing entry means no
-- highlighting even when `parser/<lang>.so` exists ('wgsl' was exactly this: a
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

return {
  {
    'nvim-treesitter/nvim-treesitter',
    -- `:TSUpdate` after every install/update. This replaces the `PackChanged`
    -- hook that the previous `vim.pack` setup used to re-run the same thing.
    build = ':TSUpdate',
    -- `now_if_args()` in the old config meant "only when Neovim is started with
    -- a file". `BufReadPre` has exactly that meaning -- it does not fire for
    -- the bare `nvim` starter, and it fires *before* the `FileType` autocmd
    -- below runs, so highlighting is ready for the very first buffer.
    -- `BufNewFile` covers `:e new-file.lua` for a file that does not exist yet.
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- Define languages which will have parsers installed and auto enabled.
      local isnt_installed = function(lang)
        return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
      end
      local to_install = vim.tbl_filter(isnt_installed, languages)
      if #to_install > 0 then
        vim.api.nvim_create_autocmd('VimEnter', {
          once = true,
          callback = function()
            require('nvim-treesitter').install(to_install)
          end,
          desc = 'Install missing tree-sitter parsers',
        })
      end

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
      Config.new_autocmd('FileType', filetypes, function(ev)
        vim.treesitter.start(ev.buf)
      end, 'Start tree-sitter')
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    event = { 'BufReadPre', 'BufNewFile' },
  },
}
