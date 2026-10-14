-- ┌──────────────────────────┐
-- │ Built-in Neovim behavior │
-- └──────────────────────────┘
--
-- This file defines Neovim's built-in behavior. The goal is to improve overall
-- usability in a way that works best with MINI.
--
-- Here `vim.o.xxx = value` sets default value of option `xxx` to `value`.
-- See `:h 'xxx'` (replace `xxx` with actual option name).
--
-- Option values can be customized on a per buffer or window basis.
-- See 'after/ftplugin/' for common example.
--
-- Notes:
-- - Some options (like `:h 'exrc'`) need to be set before this file is sourced.
--   Set them directly at the bottom of the 'init.lua' file.

-- stylua: ignore start
-- The next part (until `-- stylua: ignore end`) is aligned manually for easier
-- reading. Consider preserving this or remove `-- stylua` lines to autoformat.

-- General ====================================================================
vim.g.mapleader = ' ' -- Use `<Space>` as <Leader> key

vim.o.mouse       = 'a'            -- Enable mouse
vim.o.mousescroll = 'ver:25,hor:6' -- Customize mouse scroll
vim.o.switchbuf   = 'usetab'       -- Use already opened buffers when switching
vim.o.undofile    = true           -- Enable persistent undo

vim.o.shada = "'100,<50,s10,:1000,/100,@100,h" -- Limit ShaDa file (for startup)

-- UI =========================================================================
vim.o.breakindent    = true       -- Indent wrapped lines to match line start
vim.o.breakindentopt = 'list:-1'  -- Add padding for lists (if 'wrap' is set)
vim.o.colorcolumn    = '+1'       -- Draw column on the right of maximum width
vim.o.cursorline     = true       -- Enable current line highlighting
vim.o.linebreak      = true       -- Wrap lines at 'breakat' (if 'wrap' is set)
vim.o.list           = true       -- Show helpful text indicators
vim.o.number         = true       -- Show line numbers
vim.o.pumborder      = 'single'   -- Use border in popup menu
vim.o.pumheight      = 10         -- Make popup menu smaller
vim.o.pummaxwidth    = 100        -- Make popup menu not too wide
vim.o.ruler          = false      -- Don't show cursor coordinates
vim.o.shortmess      = 'CFOSWaco' -- Disable some built-in completion messages
vim.o.showmode       = false      -- Don't show mode in command line
vim.o.signcolumn     = 'yes'      -- Always show signcolumn (less flicker)
vim.o.splitbelow     = true       -- Horizontal splits will be below
vim.o.splitkeep      = 'screen'   -- Reduce scroll during window split
vim.o.splitright     = true       -- Vertical splits will be to the right
vim.o.winborder      = 'single'   -- Use border in floating windows
vim.o.wrap           = false      -- Don't visually wrap lines (toggle with \w)

vim.o.cursorlineopt  = 'screenline,number' -- Show cursor line per screen line

-- Special UI symbols. More is set via 'mini.basics' later.
vim.o.fillchars = 'eob: ,fold:╌'
vim.o.listchars = 'extends:…,nbsp:␣,precedes:…,tab:> '

-- Folds (see `:h fold-commands`, `:h zM`, `:h zR`, `:h zA`, `:h zj`)
vim.o.foldlevel   = 10       -- Fold nothing by default; set to 0 or 1 to fold
vim.o.foldmethod  = 'indent' -- Fold based on indent level
vim.o.foldnestmax = 10       -- Limit number of fold levels
vim.o.foldtext    = ''       -- Show text under fold with its highlighting

-- Editing ====================================================================
vim.o.autoindent    = true    -- Use auto indent
vim.o.expandtab     = true    -- Convert tabs to spaces
vim.o.formatoptions = 'rqnl1j'-- Improve comment editing
vim.o.ignorecase    = true    -- Ignore case during search
vim.o.incsearch     = true    -- Show search matches while typing
vim.o.infercase     = true    -- Infer case in built-in completion
vim.o.shiftwidth    = 2       -- Use this number of spaces for indentation
vim.o.smartcase     = true    -- Respect case if search pattern has upper case
vim.o.smartindent   = true    -- Make indenting smart
vim.o.spelloptions  = 'camel' -- Treat camelCase word parts as separate words
vim.o.tabstop       = 2       -- Show tab as this number of spaces
vim.o.virtualedit   = 'block' -- Allow going past end of line in blockwise mode

vim.o.iskeyword = '@,48-57,_,192-255,-' -- Treat dash as `word` textobject part

-- Pattern for a start of numbered list (used in `gw`). This reads as
-- "Start of list item is: at least one special character (digit, -, +, *)
-- possibly followed by punctuation (. or `)`) followed by at least one space".
vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]]

-- Built-in completion
vim.o.complete        = '.,w,b,kspell'                  -- Use less sources
vim.o.completeopt     = 'menuone,noselect,fuzzy,nosort' -- Use custom behavior
vim.o.completetimeout = 100                             -- Limit sources delay

-- Autocommands ===============================================================

-- Don't auto-wrap comments and don't insert comment leader after hitting 'o'.
-- Do on `FileType` to always override these changes from filetype plugins.
local f = function() vim.cmd('setlocal formatoptions-=c formatoptions-=o') end
Config.new_autocmd('FileType', nil, f, "Proper 'formatoptions'")

-- There are other autocommands created by 'mini.basics'. See 'plugin/30_mini.lua'.

-- Diagnostics ================================================================

-- Neovim has built-in support for showing diagnostic messages. This configures
-- a more conservative display while still being useful.
-- See `:h vim.diagnostic` and `:h vim.diagnostic.config()`.
local diagnostic_opts = {
  -- Show signs on top of any other sign, but only for warnings and errors
  signs = { priority = 9999, severity = { min = 'WARN', max = 'ERROR' } },

  -- Show all diagnostics as underline (for their messages type `<Leader>ld`)
  underline = { severity = { min = 'HINT', max = 'ERROR' } },

  -- Show more details immediately for errors on the current line
  virtual_lines = false,
  virtual_text = {
    current_line = true,
    severity = { min = 'ERROR', max = 'ERROR' },
  },

  -- Don't update diagnostics when typing
  update_in_insert = false,
}

-- Use `later()` to avoid sourcing `vim.diagnostic` on startup
Config.later(function() vim.diagnostic.config(diagnostic_opts) end)
-- stylua: ignore end

-- Personal ===================================================================
-- Ported from the previous LazyVim config ('lua/config/options.lua').

-- stylua: ignore start
vim.o.relativenumber = true   -- MiniMax sets absolute line numbers
vim.o.laststatus     = 3      -- Global statusline
vim.o.scrolloff      = 30     -- Keep cursor away from screen edges
vim.o.cursorcolumn   = true   -- Highlight current column
vim.o.autoread       = true   -- Re-read files changed outside of Neovim
vim.o.spelllang      = 'en'
vim.o.winbl          = 25     -- Slight transparency in floating windows
vim.o.pumblend       = 15     -- Popup menu blend
vim.o.shell          = 'fish' -- Shell used by `:terminal`
vim.o.updatetime     = 1000   -- Faster CursorHold (signature/hover popup)
-- stylua: ignore end

-- Clipboard sync via X11's xsel (through XWayland; `DISPLAY` is set here).
--
-- IMPORTANT: On this ChromeOS/Crostini setup `wl-paste` BLOCKS FOREVER on the
-- regular clipboard -- even when a clipboard owner exists. The Wayland data
-- device exposed by sommelier never delivers the selection, so `wl-paste` (and
-- therefore Neovim) hangs. That froze startup because 'yanky.nvim' reads the
-- default register on `VimEnter`, and with 'clipboard=unnamedplus' the default
-- register is `+` (the system clipboard). `xsel` works, so set it explicitly
-- instead of relying on Neovim's Wayland-first auto-detection.
vim.g.clipboard = {
  name = 'xsel',
  copy = { ['+'] = 'xsel -b -i', ['*'] = 'xsel -p -i' },
  paste = { ['+'] = 'xsel -b -o', ['*'] = 'xsel -p -o' },
  cache_enabled = true,
}
vim.o.clipboard = 'unnamedplus'

-- Autocmds ===================================================================

-- On idle, show signature help (falling back to hover) plus diagnostics of the
-- current line in a floating window. Ported as-is from 'lua/config/autocmds.lua'
-- of the previous LazyVim config, including the "skip while a floating window
-- is already open" guard.
local last_symbol = nil

local get_line_diagnostics = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  return vim.diagnostic.get(bufnr, { lnum = line })
end

local show_diagnostics = function(diags)
  if #diags == 0 then return end
  local msg = {}
  for _, d in ipairs(diags) do
    table.insert(msg, d.message)
  end
  vim.lsp.util.open_floating_preview(msg, 'plaintext', { border = 'rounded' })
end

local symbol_at_cursor = function()
  local cword = vim.fn.expand('<cword>')
  local bufnr = vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_get_name(bufnr) .. ':' .. cword
end

local append_diagnostics = function(contents, diags)
  if #diags == 0 then return contents end
  table.insert(contents, '')
  table.insert(contents, 'Diagnostics:')
  for _, d in ipairs(diags) do
    table.insert(contents, '- ' .. d.message)
  end
  return contents
end

local show_signature_or_hover = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_position_params(0, 'utf-8')

  -- Avoid duplicate trigger if still on the same symbol
  local symbol_id = symbol_at_cursor()
  if symbol_id == last_symbol then return end
  last_symbol = symbol_id

  local diags = get_line_diagnostics()

  -- Try signature help first
  vim.lsp.buf_request(bufnr, 'textDocument/signatureHelp', params, function(err, result)
    if err or not result or not result.signatures or vim.tbl_isempty(result.signatures) then
      -- Fall back to hover if there is no signature
      vim.lsp.buf_request(bufnr, 'textDocument/hover', params, function(err2, result2)
        if err2 or not result2 or not result2.contents then
          show_diagnostics(diags)
          return
        end
        local contents = vim.lsp.util.convert_input_to_markdown_lines(result2.contents)
        append_diagnostics(contents, diags)
        vim.lsp.util.open_floating_preview(contents, 'markdown', { border = 'rounded' })
      end)
      return
    end

    local contents = vim.lsp.util.convert_signature_help_to_markdown_lines(result)
    if contents and not vim.tbl_isempty(contents) then
      append_diagnostics(contents, diags)
      vim.lsp.util.open_floating_preview(contents, 'markdown', { border = 'rounded' })
    else
      show_diagnostics(diags)
    end
  end)
end

-- WGSL validation ============================================================

-- There is no `wgsl_analyzer` binary installed (see 'vim.lsp.enable()' in
-- 'plugin/40_plugins.lua' for how to add it), so WGSL files get no real language
-- server. `naga` (the Rust shader translator, `cargo install naga-cli`) parses
-- and validates a shader when given no output file, which is enough to surface
-- type and binding errors as ordinary diagnostics.
--
-- This runs on write, not on CursorHold: validation is a whole-file parse, so
-- per-keystroke checking would be wasteful. Once `wgsl_analyzer` is installed it
-- takes over and these diagnostics stop appearing -- the server reports the same
-- class of problem.
if vim.fn.executable('naga') == 1 then
  -- `set()` takes a namespace *name* but `reset()` wants the numeric namespace,
  -- so resolve it once and use the number everywhere.
  local NS = vim.api.nvim_create_namespace('naga')

  local function naga_check(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    if name == '' or vim.bo[buf].buftype ~= '' then
      return
    end

    -- `naga` colourises and exits non-zero precisely when it has something to
    -- say, so the exit status is not an error check here -- the parsed output
    -- is. Strip ANSI first or the messages arrive full of escape codes.
    local out = vim.fn.system({ 'naga', name })
    out = tostring(out):gsub('\27%[[0-9;]*m', '')
    if out == '' then
      vim.diagnostic.reset(NS, buf)
      return
    end

    local diags = {}
    -- `naga` groups each problem as a headline followed by a caret location:
    --   error: no definition in scope for identifier: `x`
    --     ┌─ file.wgsl:5:28
    -- So remember the headline and attach it to the location that follows it.
    local pending = nil
    for line in out:gmatch('[^\n]+') do
      local msg = line:match('^error:%s*(.+)$')
      if msg then
        pending = msg
      elseif pending then
        local lnum, col = line:match('┌─%s*[^:]-:(%d+):(%d+)')
        if lnum then
          diags[#diags + 1] = {
            lnum = math.max(0, tonumber(lnum) - 1),
            col = math.max(0, tonumber(col) - 1),
            -- A range is reported under a single caret in the `= ...` detail
            -- lines; one start position keeps the squiggle where the caret is.
            message = pending,
            severity = vim.diagnostic.severity.ERROR,
            source = 'naga',
          }
          pending = nil
        end
      end
    end

    if #diags > 0 then
      vim.diagnostic.set(NS, buf, diags)
    else
      vim.diagnostic.reset(NS, buf)
    end
  end

  Config.new_autocmd({ 'BufWritePost' }, { '*.wgsl' }, function(ev)
    -- Validate asynchronously so a slow parse never blocks the write.
    vim.schedule(function() naga_check(ev.buf) end)
  end, 'Validate WGSL with naga')
end

vim.api.nvim_create_autocmd('CursorHold', {
  pattern = {
    '*.sh',
    '*.fish',
    '*.ts',
    '*.tsx',
    '*.js',
    '*.jsx',
    '*.mjs',
    '*.cjs',
    '*.lua',
    '*.go',
    '*.zig',
    '*.rs',
    '*.py',
    '*.css',
    '*.html',
    '*.toml',
    '*.yml',
    '*.yaml',
    '*.wgsl',
  },
  callback = function()
    -- Skip if a floating window is already showing (user is reading hover/sig)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local config = vim.api.nvim_win_get_config(win)
      if config.relative and config.relative ~= '' then return end
    end
    show_signature_or_hover()
  end,
  group = vim.api.nvim_create_augroup('LspSignatureHoverDiagnostics', { clear = true }),
})
