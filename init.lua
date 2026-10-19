-- ┌─────────────────────────────┐
-- │ Welcome to MiniMax (Lazy)   │
-- └─────────────────────────────┘
--
-- This is a config designed to mostly use MINI. It provides out of the box
-- a stable, polished, and feature rich Neovim experience. Its structure:
--
-- ├ init.lua          Initial (this) file executed during startup
-- ├ plugin/           Files automatically sourced during startup
-- │ └── 20_keymaps.lua  Custom mappings
-- ├ lua/options.lua   Built-in Neovim behavior (required from here)
-- ├ lua/completion.lua  Path completion source used by 'complete'
-- ├ lua/plugins/      Plugin specs ('lazy.nvim' auto-discovers this)
-- │ ├── mini.lua        All MINI modules
-- │ ├── treesitter.lua  Tree-sitter and its textobjects
-- │ ├── lsp.lua         Language servers
-- │ ├── editing.lua     Formatting, renaming, yanks, dimming, find/replace
-- │ └── personal.lua    Personal plugins from the previous config
-- ├ snippets/         User defined snippets (has demo file)
-- ├ after/            Files to override behavior added by plugins
-- │ ├── ftplugin/     Files for filetype behavior
-- │ ├── lsp/          Language server configurations
-- │ └── snippets/     Higher priority snippet files
--
-- 'lua/options.lua' is a module rather than a `plugin/` file, and `init.lua`
-- requires it *before* `require('lazy').setup()`. Plugin specs are configured
-- while that call runs, so options have to be in place by then.
--
-- Config files are meant to be read, preferably inside a Neovim instance running
-- this config and opened at its root. This will help you better understand your
-- setup. Start with this file. Any order is possible, prefer the one listed above.
-- Ways of navigating your config:
-- - `<Space>` + `e` + (one of) `iokmp` - edit 'init.lua', keymaps, options,
--   mini config, or plugin specs.
-- - Inside config directory: `<Space>ff` (picker) or `<Space>ed` (explorer)
-- - Navigate existing buffers with `[b`, `]b`, or `<Space>fb`.
--
-- Config files are also meant to be customized. Initially it is a baseline of
-- a working config based on MINI. Modify it to make it yours. Some approaches:
-- - Modify already existing files in a way that keeps them consistent.
-- - Add new files in a way that keeps config consistent.
--   Usually inside 'plugin/' or 'after/'.
--
-- Documentation comments like this can be found throughout the config.
-- Common conventions:
--
-- - See `:h key-notation` for key notation used.
-- - `:h xxx` means "documentation of helptag xxx". Either type text directly
--   followed by Enter or type `<Space>fh` to open a helptag fuzzy picker.
-- - "Type `<Space>fh`" means "press <Space>, followed by f, followed by h".
--   Unless said otherwise, it assumes that Normal mode is current.
-- - "See 'path/to/file'" means see open file at described path and read it.
-- - `:SomeCommand ...` or `:lua ...` means execute mentioned command.

-- ┌────────────────┐
-- │ Plugin manager │
-- └────────────────┘
--
-- This config uses 'lazy.nvim'. Specs live in 'lua/plugins/', which lazy.nvim
-- discovers automatically: a file there returns a list of plugin specifications
-- and nothing else. Example usage:
-- - `return { { 'owner/repo', event = 'VeryLazy', config = function() ... end } }`
-- - `:Lazy` - plugin manager UI (also bound to `<A-l>`, see 'plugin/20_keymaps.lua')
-- - `:Lazy update` - update all plugins
-- - `:Lazy sync` - install missing, remove unused, update rest
--
-- A spec is only *configured* when lazy.nvim decides to load it, which is what
-- the `event`/`lazy` fields control:
-- - `lazy = false` - during startup. Used by 'mini.nvim', which provides the
--   colorscheme, statusline and starter screen.
-- - `event = { 'BufReadPre', 'BufNewFile' }` - when a file is read. This is the
--   direct successor of the old `now_if_args()` helper: those helpers ran
--   "now, but only if Neovim was started with a file", which is exactly when
--   `BufReadPre` fires. Tree-sitter and the language servers have to be
--   configured before the first `FileType`, hence a read event rather than a
--   later startup event.
-- - `event = 'VeryLazy'` - right after the first screen draw. This is the old
--   `later()` helper, and is used for anything whose keymaps can only be pressed
--   long after startup.
--
-- See also:
-- - `:help lazy.nvim` - full documentation
-- - `:Lazy help` - the same, inside Neovim
--
-- Note on plugins needed before lazy.nvim runs: none. The `Config.now`/`later`
-- helpers above are implemented with plain Neovim APIs precisely so that
-- 'lua/options.lua' can use them before any plugin exists on the 'runtimepath'.

-- Define config table to be able to pass data between scripts
-- It is a global variable which can be use both as `_G.Config` and `Config`
_G.Config = {}

-- Define custom autocommand group and helper to create an autocommand.
-- Autocommands are Neovim's way to define actions that are executed on events
-- (like creating a buffer, setting an option, etc.).
--
-- See also:
-- - `:h autocommand`
-- - `:h nvim_create_augroup()`
-- - `:h nvim_create_autocmd()`
local gr = vim.api.nvim_create_augroup('custom-config', {})
Config.new_autocmd = function(event, pattern, callback, desc)
  local opts = { group = gr, pattern = pattern, callback = callback, desc = desc }
  vim.api.nvim_create_autocmd(event, opts)
end

-- Loading helpers used to organize config into fail-safe parts. They defer a
-- chunk of setup so that a broken plugin cannot take the whole startup down, and
-- so that work which is not needed for the first screen draw stays off it.
--
-- Example usage:
-- - `now` - execute immediately. Use for what must be executed during startup.
--   Like colorscheme, statusline, tabline, dashboard, etc.
-- - `later` - execute a bit later. Use for things not needed during startup.
-- - `now_if_args` - use only if needed during startup when Neovim is started
--   like `nvim -- path/to/file`, but otherwise delaying is fine.
--   (Inside lazy.nvim specs prefer `event = { 'BufReadPre', 'BufNewFile' }`,
--   which expresses the same intent declaratively.)
-- - Others are better used only if the above is not enough for good performance.
--   Use only if you are comfortable with adding complexity to your config:
--   - `on_event` - execute once on a first matched event. Like "delay until
--     first Insert mode enter": `on_event('InsertEnter', function() ... end)`.
--   - `on_filetype` - execute once on a first matched filetype. Like "delay
--     until first Lua file": `on_filetype('lua', function() ... end)`.
--
-- These used to be thin wrappers around `MiniMisc.safely()`, but mini.nvim is now
-- loaded by lazy.nvim from 'lua/plugins/mini.lua' -- i.e. *after* this file runs,
-- while 'lua/options.lua' (required above `require('lazy').setup()`) already
-- calls `Config.later`. Depending on mini.misc would mean either an ordering
-- constraint or a special case for the pre-lazy phase. The behaviour is small
-- enough to inline: run `f`, and if it throws, notify with the traceback instead
-- of taking the whole startup down.
local safely = function(f)
  local ok, err = xpcall(f, debug.traceback)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR, { title = 'Config' })
  end
end
Config.now = function(f)
  safely(f)
end
Config.later = function(f)
  -- Same timing as `MiniMisc.safely('later', ...)`: onto the main loop, so it
  -- runs after the rest of startup has been sourced.
  vim.schedule(function()
    safely(f)
  end)
end
Config.now_if_args = vim.fn.argc(-1) > 0 and Config.now or Config.later
Config.on_event = function(ev, f)
  vim.api.nvim_create_autocmd(ev, {
    once = true,
    callback = function()
      safely(f)
    end,
  })
end
Config.on_filetype = function(ft, f)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = ft,
    once = true,
    callback = function()
      safely(f)
    end,
  })
end

-- 'mdx' (Markdown + JSX) gets its own filetype and is parsed with the 'markdown'
-- tree-sitter parser (registered in 'lua/plugins/treesitter.lua'), so
-- render-markdown and image.nvim work in '*.mdx' files too. This has to happen
-- before any buffer gets a FileType, i.e. it cannot live in a lazy spec.
vim.filetype.add({ extension = { mdx = 'mdx' } })

-- Built-in Neovim behavior. See 'lua/options.lua'.
require('options')

-- Plugin manager. Specs come from 'lua/plugins/'.
--
-- The first argument is the spec: `'plugins'` is lazy.nvim's shorthand for
-- importing every file in 'lua/plugins/*.lua' (see `:help lazy.nvim`, the
-- `SPEC` section). The second argument holds the manager options.
--
-- lazy.nvim is the one plugin that cannot manage itself, so it is cloned here on
-- first run. Everything else is installed by lazy itself (`install.missing`
-- below), and the resolved revisions are pinned in 'lazy-lock.json'.
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { 'Failed to clone lazy.nvim:\n' .. out, 'ErrorMsg' } }, true, {})
    vim.cmd('cq')
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins', {
  -- Install any spec from 'lua/plugins/' that is not on disk yet. Without this,
  -- a fresh machine needs a manual `:Lazy install` before the config is usable.
  install = { missing = true },
  -- 'checker' only refreshes a version cache on disk in the background. This
  -- config updates deliberately, with `:Lazy update`.
  checker = { enabled = false },
  -- Every plugin here is pure Lua and is installed from git, which is what the
  -- previous 'vim.pack' setup did. lazy.nvim's luarocks support is on by default
  -- and would otherwise install `hererocks` into 'lazy-rocks/' on first run, so
  -- switch it off rather than pull in a second package manager.
  rocks = { enabled = false },
  -- Match the rest of the config, which draws every floating window with a
  -- single-line border (`'winborder'` in 'lua/options.lua').
  ui = { border = 'single' },
})
