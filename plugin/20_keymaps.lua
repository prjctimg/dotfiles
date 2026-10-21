-- ┌─────────────────┐
-- │ Custom mappings │
-- └─────────────────┘
--
-- This file contains definitions of custom general and Leader mappings.

-- General mappings ===========================================================

-- Use this section to add custom general mappings. See `:h vim.keymap.set()`.

-- An example helper to create a Normal mode mapping
local nmap = function(lhs, rhs, desc)
  -- See `:h vim.keymap.set()`
  vim.keymap.set('n', lhs, rhs, { desc = desc })
end

-- Paste linewise before/after current line
-- Usage: `yiw` to yank a word and `]p` to put it on the next line.
nmap('[p', '<Cmd>exe "iput! " . v:register<CR>', 'Paste Above')
nmap(']p', '<Cmd>exe "iput "  . v:register<CR>', 'Paste Below')

-- Many general mappings are created by 'mini.basics'. See 'lua/plugins/mini.lua'

-- stylua: ignore start
-- The next part (until `-- stylua: ignore end`) is aligned manually for easier
-- reading. Consider preserving this or remove `-- stylua` lines to autoformat.

-- Leader mappings ============================================================

-- Neovim has the concept of a Leader key (see `:h <Leader>`). It is a configurable
-- key that is primarily used for "workflow" mappings (opposed to text editing).
-- Like "open file explorer", "create scratch buffer", "pick from buffers".
--
-- In 'lua/options.lua' <Leader> is set to <Space>, i.e. press <Space>
-- whenever there is a suggestion to press <Leader>.
--
-- This config uses a "two key Leader mappings" approach: first key describes
-- semantic group, second key executes an action. Both keys are usually chosen
-- to create some kind of mnemonic.
-- Example: `<Leader>f` groups "find" type of actions; `<Leader>ff` - find files.
-- Use this section to add Leader mappings in a structural manner.
--
-- Usually if there are global and local kinds of actions, lowercase second key
-- denotes global and uppercase - local.
-- Example: `<Leader>fs` / `<Leader>fS` - find workspace/document LSP symbols.
--
-- Many of the mappings use 'mini.nvim' modules set up in 'lua/plugins/mini.lua'.

-- Create a global table with information about Leader groups in certain modes.
-- This is used to provide 'mini.clue' with extra clues.
-- Add an entry if you create a new group.
Config.leader_group_clues = {
  { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
  { mode = 'n', keys = '<Leader>e', desc = '+Explore/Edit' },
  { mode = 'n', keys = '<Leader>f', desc = '+Find' },
  { mode = 'n', keys = '<Leader>g', desc = '+Git' },
  { mode = 'n', keys = '<Leader>l', desc = '+Language' },
  { mode = 'n', keys = '<Leader>m', desc = '+Map' },
  { mode = 'n', keys = '<Leader>o', desc = '+Other' },
  { mode = 'n', keys = '<Leader>q', desc = '+Quit' },
  { mode = 'n', keys = '<Leader>s', desc = '+Session' },
  { mode = 'n', keys = '<Leader>t', desc = '+Terminal/Config' },
  { mode = 'n', keys = '<Leader>u', desc = '+Utility' },
  { mode = 'n', keys = '<Leader>v', desc = '+Visits' },

  { mode = 'x', keys = '<Leader>g', desc = '+Git' },
  { mode = 'x', keys = '<Leader>l', desc = '+Language' },
}

-- Helpers for a more concise `<Leader>` mappings.
-- Most of the mappings use `<Cmd>...<CR>` string as a right hand side (RHS) in
-- an attempt to be more concise yet descriptive. See `:h <Cmd>`.
-- This approach also doesn't require the underlying commands/functions to exist
-- during mapping creation: a "lazy loading" approach to improve startup time.
local nmap_leader = function(suffix, rhs, desc)
  vim.keymap.set('n', '<Leader>' .. suffix, rhs, { desc = desc })
end
local xmap_leader = function(suffix, rhs, desc)
  vim.keymap.set('x', '<Leader>' .. suffix, rhs, { desc = desc })
end

-- b is for 'Buffer'. Common usage:
-- - `<Leader>bs` - create scratch (temporary) buffer
-- - `<Leader>ba` - navigate to the alternative buffer
-- - `<Leader>bw` - wipeout (fully delete) current buffer
local new_scratch_buffer = function()
  vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
end

nmap_leader('ba', '<Cmd>b#<CR>',                                 'Alternate')
nmap_leader('bd', '<Cmd>lua MiniBufremove.delete()<CR>',         'Delete')
nmap_leader('bD', '<Cmd>lua MiniBufremove.delete(0, true)<CR>',  'Delete!')
nmap_leader('bs', new_scratch_buffer,                            'Scratch')
nmap_leader('bw', '<Cmd>lua MiniBufremove.wipeout()<CR>',        'Wipeout')
nmap_leader('bW', '<Cmd>lua MiniBufremove.wipeout(0, true)<CR>', 'Wipeout!')

-- e is for 'Explore' and 'Edit'. Common usage:
-- - `<Leader>ed` - open explorer at current working directory
-- - `<Leader>ef` - open directory of current file (needs to be present on disk)
-- - `<Leader>ei` - edit 'init.lua'
-- - All mappings that use `edit_config_file` - edit config files
local edit_config_file = function(path)
  return string.format('<Cmd>edit %s/%s<CR>', vim.fn.stdpath('config'), path)
end
-- `MiniFiles` is set up in a `now_if_args()` block (see 'lua/plugins/mini.lua'),
-- which defers when Neovim is started without a file. Set it up on demand so
-- `<Leader>ed` / `<Leader>ef` also work from the starter screen. `get_name` is a
-- function, not a value, because the current buffer can change between the
-- mapping being defined and the mapping being pressed.
local open_files = function(get_name)
  return function()
    if not MiniFiles then pcall(require('mini.files').setup) end
    MiniFiles.open(get_name and get_name() or nil)
  end
end
local explore_at_file = open_files(function() return vim.api.nvim_buf_get_name(0) end)
local explore_quickfix = function()
  vim.cmd(vim.fn.getqflist({ winid = true }).winid ~= 0 and 'cclose' or 'copen')
end
local explore_locations = function()
  vim.cmd(vim.fn.getloclist(0, { winid = true }).winid ~= 0 and 'lclose' or 'lopen')
end

nmap_leader('ed', open_files(),                             'Directory')
nmap_leader('ef', explore_at_file,                          'File directory')
nmap_leader('ei', '<Cmd>edit $MYVIMRC<CR>',                  'init.lua')
nmap_leader('ek', edit_config_file('plugin/20_keymaps.lua'), 'Keymaps config')
nmap_leader('em', edit_config_file('lua/plugins/mini.lua'),  'MINI config')
nmap_leader('en', '<Cmd>lua MiniNotify.show_history()<CR>', 'Notifications')
nmap_leader('eo', edit_config_file('lua/options.lua'),       'Options config')
nmap_leader('ep', edit_config_file('lua/plugins'),           'Plugins specs')
nmap_leader('eq', explore_quickfix,                         'Quickfix list')
nmap_leader('eQ', explore_locations,                        'Location list')

-- f is for 'Fuzzy Find'. Common usage:
-- - `<Leader>ff` - find files; for best performance requires `ripgrep`
-- - `<Leader>fg` - find inside files; requires `ripgrep`
-- - `<Leader>fh` - find help tag
-- - `<Leader>fr` - resume latest picker
-- - `<Leader>fv` - all visited paths; requires 'mini.visits'
--
-- All these use 'mini.pick'. See `:h MiniPick-overview` for an overview.
local pick_added_hunks_buf = '<Cmd>Pick git_hunks path="%" scope="staged"<CR>'
local pick_workspace_symbols_live = '<Cmd>Pick lsp scope="workspace_symbol_live"<CR>'

nmap_leader('f/', '<Cmd>Pick history scope="/"<CR>',            '"/" history')
nmap_leader('f:', '<Cmd>Pick history scope=":"<CR>',            '":" history')
nmap_leader('fa', '<Cmd>Pick git_hunks scope="staged"<CR>',     'Added hunks (all)')
nmap_leader('fA', pick_added_hunks_buf,                         'Added hunks (buf)')
nmap_leader('fb', '<Cmd>Pick buffers<CR>',                      'Buffers')
nmap_leader('fc', '<Cmd>Pick git_commits<CR>',                  'Commits (all)')
nmap_leader('fC', '<Cmd>Pick git_commits path="%"<CR>',         'Commits (buf)')
nmap_leader('fd', '<Cmd>Pick diagnostic scope="all"<CR>',       'Diagnostic workspace')
nmap_leader('fD', '<Cmd>Pick diagnostic scope="current"<CR>',   'Diagnostic buffer')
nmap_leader('ff', '<Cmd>Pick files<CR>',                        'Files')
nmap_leader('fg', '<Cmd>Pick grep_live<CR>',                    'Grep live')
nmap_leader('fG', '<Cmd>Pick grep pattern="<cword>"<CR>',       'Grep current word')
nmap_leader('fh', '<Cmd>Pick help<CR>',                         'Help tags')
nmap_leader('fH', '<Cmd>Pick hl_groups<CR>',                    'Highlight groups')
nmap_leader('fl', '<Cmd>Pick buf_lines scope="all"<CR>',        'Lines (all)')
nmap_leader('fL', '<Cmd>Pick buf_lines scope="current"<CR>',    'Lines (buf)')
nmap_leader('fm', '<Cmd>Pick git_hunks<CR>',                    'Modified hunks (all)')
nmap_leader('fM', '<Cmd>Pick git_hunks path="%"<CR>',           'Modified hunks (buf)')
nmap_leader('fr', '<Cmd>Pick resume<CR>',                       'Resume')
nmap_leader('fR', '<Cmd>Pick lsp scope="references"<CR>',       'References (LSP)')
nmap_leader('fs', pick_workspace_symbols_live,                  'Symbols workspace (live)')
nmap_leader('fS', '<Cmd>Pick lsp scope="document_symbol"<CR>',  'Symbols document')
nmap_leader('fv', '<Cmd>Pick visit_paths cwd=""<CR>',           'Visit paths (all)')
nmap_leader('fV', '<Cmd>Pick visit_paths<CR>',                  'Visit paths (cwd)')

-- g is for 'Git'. Common usage:
-- - `<Leader>gs` - show information at cursor
-- - `<Leader>go` - toggle 'mini.diff' overlay to show in-buffer unstaged changes
-- - `<Leader>gd` - show unstaged changes as a patch in separate tabpage
-- - `<Leader>gL` - show Git log of current file
local git_log_cmd = [[Git log --pretty=format:\%h\ \%as\ │\ \%s --topo-order]]
local git_log_buf_cmd = git_log_cmd .. ' --follow -- %'

nmap_leader('ga', '<Cmd>Git diff --cached<CR>',             'Added diff')
nmap_leader('gA', '<Cmd>Git diff --cached -- %<CR>',        'Added diff buffer')
nmap_leader('gc', '<Cmd>Git commit<CR>',                    'Commit')
nmap_leader('gC', '<Cmd>Git commit --amend<CR>',            'Commit amend')
nmap_leader('gd', '<Cmd>Git diff<CR>',                      'Diff')
nmap_leader('gD', '<Cmd>Git diff -- %<CR>',                 'Diff buffer')
nmap_leader('gl', '<Cmd>' .. git_log_cmd .. '<CR>',         'Log')
nmap_leader('gL', '<Cmd>' .. git_log_buf_cmd .. '<CR>',     'Log buffer')
nmap_leader('go', '<Cmd>lua MiniDiff.toggle_overlay()<CR>', 'Toggle overlay')
nmap_leader('gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>',  'Show at cursor')

xmap_leader('gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>', 'Show at selection')

-- l is for 'Language'. Common usage:
-- - `<Leader>ld` - show more diagnostic details in a floating window
-- - `<Leader>lr` - perform rename via LSP
-- - `<Leader>ls` - navigate to source definition of symbol under cursor
--
-- NOTE: most LSP mappings represent a more structured way of replacing built-in
-- LSP mappings (like `:h gra` and others). This is needed because `gr` is mapped
-- by an "replace" operator in 'mini.operators' (which is more commonly used).

-- Rename through 'inc-rename.nvim' (setup in 'lua/plugins/editing.lua'): it
-- previews the rename in the command-preview window as the new name is typed, so
-- a rename spanning many files can be reviewed before it is applied instead of
-- being committed blind. `:IncRename` is a no-op when no attached server offers
-- `textDocument/rename`, so fall back to the plain LSP rename in that case --
-- that keeps the key useful for servers that implement `rename` without
-- `prepareRename`, and avoids a dead key where there is no server at all.
local inc_rename = function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if client:supports_method('textDocument/rename') then
      vim.cmd('IncRename')
      return
    end
  end
  vim.lsp.buf.rename()
end

nmap_leader('la', '<Cmd>lua vim.lsp.buf.code_action()<CR>',     'Actions')
nmap_leader('ld', '<Cmd>lua vim.diagnostic.open_float()<CR>',   'Diagnostic popup')
nmap_leader('lf', '<Cmd>lua require("conform").format()<CR>',   'Format')
nmap_leader('li', '<Cmd>lua vim.lsp.buf.implementation()<CR>',  'Implementation')
nmap_leader('lh', '<Cmd>lua vim.lsp.buf.hover()<CR>',           'Hover')
nmap_leader('ll', '<Cmd>lua vim.lsp.codelens.run()<CR>',        'Lens')
nmap_leader('lr', inc_rename,                                   'Rename')
nmap_leader('lR', '<Cmd>lua vim.lsp.buf.references()<CR>',      'References')
nmap_leader('ls', '<Cmd>lua vim.lsp.buf.definition()<CR>',      'Source definition')
nmap_leader('lt', '<Cmd>lua vim.lsp.buf.type_definition()<CR>', 'Type definition')

xmap_leader('lf', '<Cmd>lua require("conform").format()<CR>', 'Format selection')

-- m is for 'Map'. Common usage:
-- - `<Leader>mt` - toggle map from 'mini.map' (closed by default)
-- - `<Leader>mf` - focus on the map for fast navigation
-- - `<Leader>ms` - change map's side (if it covers something underneath)
nmap_leader('mf', '<Cmd>lua MiniMap.toggle_focus()<CR>', 'Focus (toggle)')
nmap_leader('mr', '<Cmd>lua MiniMap.refresh()<CR>',      'Refresh')
nmap_leader('ms', '<Cmd>lua MiniMap.toggle_side()<CR>',  'Side (toggle)')
nmap_leader('mt', '<Cmd>lua MiniMap.toggle()<CR>',       'Toggle')

-- o is for 'Other'. Common usage:
-- - `<Leader>oz` - toggle between "zoomed" and regular view of current buffer
nmap_leader('or', '<Cmd>lua MiniMisc.resize_window()<CR>', 'Resize to default width')
nmap_leader('ot', '<Cmd>lua MiniTrailspace.trim()<CR>',    'Trim trailspace')
nmap_leader('oz', '<Cmd>lua MiniMisc.zoom()<CR>',          'Zoom toggle')

-- s is for 'Session'. Common usage:
-- - `<Leader>sn` - start new session
-- - `<Leader>sr` - read previously started session
-- - `<Leader>sR` - restart Neovim preserving current session
local session_new = 'vim.ui.input({ prompt = "Session name: " }, MiniSessions.write)'

nmap_leader('sd', '<Cmd>lua MiniSessions.select("delete")<CR>', 'Delete')
nmap_leader('sn', '<Cmd>lua ' .. session_new .. '<CR>',         'New')
nmap_leader('sr', '<Cmd>lua MiniSessions.select("read")<CR>',   'Read')
nmap_leader('sR', '<Cmd>lua MiniSessions.restart()<CR>',        'Restart')
nmap_leader('sw', '<Cmd>lua MiniSessions.write()<CR>',          'Write current')

-- t is for 'Terminal'
nmap_leader('tT', '<Cmd>horizontal term<CR>', 'Terminal (horizontal)')
nmap_leader('tt', '<Cmd>vertical term<CR>',   'Terminal (vertical)')

-- v is for 'Visits'. Common usage:
-- - `<Leader>vv` - add    "core" label to current file.
-- - `<Leader>vV` - remove "core" label to current file.
-- - `<Leader>vc` - pick among all files with "core" label.
local make_pick_core = function(cwd, desc)
  return function()
    local sort_latest = MiniVisits.gen_sort.default({ recency_weight = 1 })
    local local_opts = { cwd = cwd, filter = 'core', sort = sort_latest }
    MiniExtra.pickers.visit_paths(local_opts, { source = { name = desc } })
  end
end

nmap_leader('vc', make_pick_core('',  'Core visits (all)'),       'Core visits (all)')
nmap_leader('vC', make_pick_core(nil, 'Core visits (cwd)'),       'Core visits (cwd)')
nmap_leader('vv', '<Cmd>lua MiniVisits.add_label("core")<CR>',    'Add "core" label')
nmap_leader('vV', '<Cmd>lua MiniVisits.remove_label("core")<CR>', 'Remove "core" label')
nmap_leader('vl', '<Cmd>lua MiniVisits.add_label()<CR>',          'Add label')
nmap_leader('vL', '<Cmd>lua MiniVisits.remove_label()<CR>',       'Remove label')
-- stylua: ignore end

-- Personal ===================================================================
-- Ported from the previous LazyVim config ('lua/config/keymaps.lua').
-- Helper for the "raw" (remappable, silent) mappings used below.
local map = function(mode, key, rhs, opts)
  vim.keymap.set(mode, key, rhs, vim.tbl_extend('force', { noremap = false, silent = true }, opts or {}))
end

-- Undo-tree picker (native; no undotree plugin needed). Shared by `<Leader>u`
-- and `<A-u>`. Forward-declared here so the Leader mapping can reference it.
local undo_tree = function()
  local und = vim.fn.undotree()
  local items = {}
  for _, e in ipairs(und.entries or {}) do
    if e.seq > 0 then
      local mark = (e.seq == und.seq_cur) and '▶ ' or (e.newhead and '·  ' or '   ')
      local n = e.changes or 1
      local changes = (n >= 2) and (' (' .. n .. ' changes)') or ''
      local kind = e.save and 'save' or 'undo'
      -- `os.date`'s second argument must be a number; be explicit so a `nil` or
      -- non-numeric time from `undotree()` falls back to 0 (epoch) instead of
      -- raising "bad argument".
      local time = tonumber(e.time) or tonumber(und.time_cur) or 0
      table.insert(items, {
        id = e.seq,
        text = string.format('%s%s %s%s', mark, os.date('%H:%M:%S', time), kind, changes),
      })
    end
  end
  if #items == 0 then
    vim.notify('No undo history in this buffer', vim.log.levels.INFO)
    return
  end
  require('mini.pick').start({
    source = {
      items = items,
      name = 'Undo history',
      choose = function(item)
        vim.cmd('undo ' .. item.id)
      end,
    },
  })
end

-- ╭──────────────────────────────────────────────────────────╮
-- │ LazyVim-style buffer mappings (ported from lazyvim)    │
-- ╰──────────────────────────────────────────────────────────╯

-- Switch to alternate buffer
map('n', '<Leader><Leader>', '<Cmd>b#<CR>', { desc = 'Switch to alternate buffer' })

-- Buffer navigation
map('n', '<Leader>bn', '<Cmd>bnext<CR>', { desc = 'Next buffer' })
map('n', '<Leader>bp', '<Cmd>bprevious<CR>', { desc = 'Previous buffer' })
-- Delete all other listed buffers (LazyVim `<Leader>bo`)
map('n', '<Leader>bo', function()
  local cur = vim.api.nvim_get_current_buf()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr ~= cur and vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
    end
  end
end, { desc = 'Delete other buffers' })

-- ╭──────────────────────────────────────────────────────────╮
-- │ LazyVim-style editing mappings                         │
-- ╰──────────────────────────────────────────────────────────╯

-- Comment toggle (LazyVim `<Leader>/`); the command palette moved to `<Leader>:`
map('n', '<Leader>/', 'gcc', { desc = 'Comment toggle' })
map('v', '<Leader>/', 'gc', { desc = 'Comment toggle' })
map('n', '<Leader>:', '<Cmd>Pick commands<CR>', { desc = 'Command palette' })

-- Undo tree (native picker; undotree plugin is not installed)
map('n', '<Leader>u', undo_tree, { desc = 'Undo tree' })

-- ╭──────────────────────────────────────────────────────────╮
-- │ <Leader>u — UI (ported from LazyVim's "ui" group)        │
-- ╰──────────────────────────────────────────────────────────╯

-- LazyVim's <Leader>u group is one consistent "flip a visual/editor setting"
-- namespace, so the two-key convention applies: lowercase flips it, uppercase
-- where it makes sense picks the *inverse* or a stronger variant. The mapping
-- set below is LazyVim's, expressed through the 'mini.nvim' equivalents this
-- config actually has; a setting with no counterpart here (dimming, smooth
-- scroll, indent guides, git signs) is omitted rather than faked with something
-- that behaves differently.
--
-- The most valuable of these are the *display* toggles: `uL` and `ul` between
-- absolute and relative numbers, `uZ` between zoom and normal, and `uz` for a
-- full zen view -- together they cover "make this file easier to read".
local toggle = function(get, set, desc)
  return function()
    set(not get())
    vim.cmd.redraw()
  end, desc
end

-- Editing / view toggles
map(
  'n',
  '<Leader>uw',
  toggle(function()
    return vim.wo.wrap
  end, function(v)
    vim.wo.wrap = v
  end, 'Toggle wrap'),
  { desc = 'Toggle wrap' }
)
map(
  'n',
  '<Leader>us',
  toggle(function()
    return vim.wo.spell
  end, function(v)
    vim.wo.spell = v
  end, 'Toggle spell'),
  { desc = 'Toggle spelling' }
)

-- `relativenumber` is on with `number`, which is how MiniMax (and LazyVim) show
-- line numbers; `ul` turns the pair off entirely, `uL` flips which one is the
-- "absolute" one. Keep `number` implied by `relativenumber` the same way round.
map(
  'n',
  '<Leader>uL',
  toggle(function()
    return vim.wo.relativenumber
  end, function(v)
    vim.wo.relativenumber = v
  end, 'Toggle relative number'),
  { desc = 'Toggle relative number' }
)
map(
  'n',
  '<Leader>ul',
  toggle(function()
    return vim.o.number and vim.o.relativenumber
  end, function(v)
    vim.o.number = v
    vim.o.relativenumber = v
  end, 'Toggle line numbers'),
  { desc = 'Toggle line numbers' }
)

-- Diagnostics are on by default (see the 'vim.diagnostic.config' above); turn
-- the whole subsystem off for a quiet look at the code.
map(
  'n',
  '<Leader>ud',
  toggle(function()
    return not vim.diagnostic.is_enabled()
  end, function(v)
    vim.diagnostic.enable(v)
  end, 'Toggle diagnostics'),
  { desc = 'Toggle diagnostics' }
)

-- Conceal hides Markdown/Wiki link targets and similar markup by default; raise
-- the level to reveal the raw text.
map(
  'n',
  '<Leader>uc',
  toggle(function()
    return vim.wo.conceallevel == 0
  end, function(v)
    vim.wo.conceallevel = v and 2 or 0
  end, 'Toggle conceal'),
  { desc = 'Toggle conceal level' }
)

-- Tree-sitter highlighting toggle. Stopping the highlighter leaves the parser
-- in place (so textobjects keep working) but removes the syntax colours, which
-- is the quickest way to judge a file's structure vs. its styling.
map(
  'n',
  '<Leader>uT',
  toggle(function()
    -- `vim.treesitter.highlighter` is not a table on all Neovim versions, so
    -- read it through `pcall` and treat "cannot tell" as "off" rather than
    -- throwing from the mapping.
    local ok, active = pcall(function()
      return vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] == nil
    end)
    return ok and active or true
  end, function(off)
    local buf = vim.api.nvim_get_current_buf()
    if off then
      pcall(vim.treesitter.highlighter.stop, buf)
    else
      pcall(vim.treesitter.start, buf)
    end
  end, 'Toggle treesitter highlight'),
  { desc = 'Toggle Treesitter highlight' }
)

-- Light / dark. `background` is an option Vim applies to colorschemes that
-- respect it, so setting it is the portable half of a dark/light switch.
map(
  'n',
  '<Leader>ub',
  toggle(function()
    return vim.o.background == 'dark'
  end, function(v)
    vim.o.background = v and 'dark' or 'light'
  end, 'Toggle dark background'),
  { desc = 'Toggle dark background' }
)

-- Zoom (`uZ`) is 'mini.misc' zoom: one window fills the screen, so a file can be
-- read without the splits on either side. `uz` is the fuller zen treatment the
-- keymaps section already uses for `<A-z>`.
--
-- The `MiniMisc`/`MiniFiles` globals only exist once the module has been set up.
-- `lua/plugins/mini.lua` sets both up in `now_if_args()` blocks, which defer when
-- Neovim is started without a file, so on the starter screen these are not yet
-- there. `require(...).setup` is the same trick `toggle_mini_files` uses below.
local zoom = function()
  if not MiniMisc then
    pcall(require('mini.misc').setup)
  end
  -- `pcall` above can still leave `MiniMisc` unset if the module is not loaded
  -- yet (it is set up in a `now_if_args()` block, which defers on the starter
  -- screen); calling into it then throws instead of doing nothing.
  if not MiniMisc then
    vim.notify('mini.misc is not loaded yet, try again in a moment', vim.log.levels.WARN)
    return
  end
  MiniMisc.zoom()
end
map('n', '<Leader>uZ', zoom, { desc = 'Toggle zoom' })
map('n', '<Leader>uz', function()
  -- Reuse the `<A-z>` zen body so the two entry points cannot drift.
  local keys = vim.api.nvim_get_keymap('n')
  local zen = keys[vim.fn.index(keys, { pattern = '<A-z>' })]
  if zen and zen.callback then
    return zen.callback()
  end
  zoom()
end, { desc = 'Toggle zen mode' })

-- Not in LazyVim's group, but it belongs here and was already half-mapped: clear
-- the search highlight and force a repaint. `un` mirrors LazyVim's
-- "Dismiss All Notifications"; the notify history stays reachable via `en`.
map('n', '<Leader>un', function()
  MiniNotify.dismiss()
end, { desc = 'Dismiss notifications' })
map('n', '<Leader>uC', function()
  require('mini.extra').pickers.colorschemes()
end, { desc = 'Colorschemes' })

-- Native `<Leader>.`-style dot-repeat is kept untouched (registers, counts,
-- and repeat via `:h .` work as expected; no `:repeat` remap).

-- ╭──────────────────────────────────────────────────────────╮
-- │ LazyVim-style window/terminal mappings                 │
-- ╰──────────────────────────────────────────────────────────╯

-- Undo/Redo with Ctrl+Z/Y (LazyVim style)
map('n', '<C-z>', '<cmd>undo<CR>', { desc = 'Undo' })
map('n', '<C-y>', '<cmd>redo<CR>', { desc = 'Redo' })

-- LazyVim-parity additions ------------------------------------------------
map('n', '<Leader>qq', '<Cmd>qa<CR>', { desc = 'Quit all' })
map('n', '<Leader>nh', function()
  vim.cmd('nohlsearch')
end, { desc = 'Clear search highlight' })
map('n', '<Leader>ur', function()
  vim.cmd('nohlsearch')
  vim.cmd('redraw!')
end, { desc = 'Redraw / clear search highlight' })
map('n', '<Leader>fn', function()
  vim.cmd('enew')
end, { desc = 'New file' })
-- Toggle auto-format on save (see conform `format_on_save` in 'lua/plugins/editing.lua').
-- LazyVim puts the *global* switch on the lowercase key and the *buffer* switch
-- on the uppercase one (`uf` global, `uF` buffer); this config had them the
-- other way round, so both are corrected here to match.
map('n', '<Leader>uf', function()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  vim.notify('Autoformat (global): ' .. (vim.g.disable_autoformat and 'off' or 'on'))
end, { desc = 'Toggle autoformat (global)' })
map('n', '<Leader>uF', function()
  vim.b.disable_autoformat = not vim.b.disable_autoformat
  vim.notify('Autoformat (buffer): ' .. (vim.b.disable_autoformat and 'off' or 'on'))
end, { desc = 'Toggle autoformat (buffer)' })

-- (the floating-terminal mappings live in the "Floating terminals" section
-- below; this keeps a single upvalue-based implementation)

-- ╭──────────────────────────────────────────────────────────╮
-- │ General                                                │
-- ╰──────────────────────────────────────────────────────────╯

-- Enter Command-line mode (was Normal mode in the previous config)
map('n', '<C-;>', ':')

-- LSP actions
map({ 'n', 'i' }, '<A-\\>', function()
  vim.lsp.buf.code_action()
end)

-- Rename is defined once in the `<Leader>l` section above (`inc_rename`) and
-- reused here, so `<Leader>lr`, `<A-r>` and `grn` can never disagree about how
-- a rename behaves.
map({ 'n', 'i', 'v' }, '<A-r>', inc_rename, { desc = 'Rename (preview)' })
map('n', 'grn', inc_rename, { desc = 'Rename (preview)' })

-- Find & replace (was 'grug-far' in the previous config)
--
-- 'grug-far.nvim' loads on `VeryLazy`, which is a *queued* `vim.schedule` (see
-- 'lazy.nvim''s `M.very_lazy()`), so it is not guaranteed to have run when this
-- mapping is pressed -- `nvim file.lua` followed immediately by `<A-f>` hits
-- that gap. `require()` is therefore guarded and the failure is reported rather
-- than silently swallowed by a bare `pcall`, which is what made the mapping look
-- like a no-op instead of an error.
map({ 'n', 'i' }, '<A-f>', function()
  local ok, grug = pcall(require, 'grug-far')
  if not ok then
    vim.notify('grug-far is not loaded yet, try again in a moment', vim.log.levels.WARN)
    return
  end
  local name = 'grug'
  if grug.has_instance(name) then
    grug.hide_instance(name)
    return
  end
  local ext = vim.bo.buftype == '' and vim.fn.expand('%:e')
  grug.open({
    transient = true,
    prefills = { filesFilter = ext and ext ~= '' and ('*.' .. ext) or nil },
    instanceName = name,
    staticTitle = 'Find and Replace',
  })
end)

-- File explorer (mini.files) toggle
local toggle_mini_files = function()
  -- Ensure 'mini.files' is set up even if its setup is deferred by `later()`
  if not MiniFiles then
    pcall(require('mini.files').setup)
  end
  -- Fall back to the working directory for buffers without a real on-disk path
  local name = vim.api.nvim_buf_get_name(0)
  local path = (name ~= '' and vim.fn.filereadable(name) == 1) and name or vim.uv.cwd()
  pcall(function()
    if not MiniFiles.close() then
      MiniFiles.open(path, false)
    end
  end)
end
map({ 'n', 'i', 'v', 't', 'x', 'o' }, '<A-e>', toggle_mini_files)

-- Start visual mode and move the cursor
local v_mv = function(key)
  return function()
    if vim.o.selection == 'inclusive' then
      vim.cmd('normal! v' .. key)
    else
      vim.cmd('normal! V' .. key) -- Use linewise visual mode for 'exclusive'
    end
  end
end
map({ 'n', 'i', 'v', 't', 'x', 'o' }, '<S-Left>', v_mv('h'))
map({ 'n', 'i', 'v', 't', 'x', 'o' }, '<S-Up>', v_mv('k'))
map({ 'n', 'i', 'v', 't', 'x', 'o' }, '<S-Down>', v_mv('j'))
map({ 'n', 'i', 'v', 't', 'x', 'o' }, '<S-Right>', v_mv('l'))
map({ 'n', 'i', 'v' }, '<C-a>', '<ESC>gg0v$G$')
map({ 'n', 'i', 'v' }, '<ESC>', '<ESC><ESC>')
map({ 'i', 'n', 'v', 'x', 'o' }, '<C-Tab>', '<cmd>bnext<CR>')
map({ 'i', 'n', 'v', 'x', 'o' }, '<S-Tab>', '<cmd>bprevious<CR>')

-- Buffer management
map({ 'n', 'i' }, '<C-q>', function()
  if vim.api.nvim_buf_is_valid(0) then
    vim.cmd('bd')
  else
    vim.cmd('close')
  end
end)

-- Floating terminals (was 'Snacks.terminal.toggle')
--
-- `termwin` is shared by every float, but the window is captured per launch as
-- `mywin`. Without that, closing a float by hand while its job still runs leaves
-- the job's `on_exit` pointing at whatever window `termwin` holds *then*, so it
-- would close an unrelated terminal that was opened in the meantime.
local termwin
local float_term = function(cmd)
  return function()
    if termwin and vim.api.nvim_win_is_valid(termwin) then
      vim.api.nvim_win_close(termwin, true)
      termwin = nil
      return
    end
    local buf = vim.api.nvim_create_buf(false, true)
    local width, height = math.floor(vim.o.columns * 0.85), math.floor(vim.o.lines * 0.85)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local mywin = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      row = row,
      col = col,
      width = width,
      height = height,
      style = 'minimal',
      border = 'rounded',
    })
    termwin = mywin
    vim.bo[buf].buflisted = false
    vim.keymap.set('t', '<ESC>', '<C-\\><C-n>', { buffer = buf })
    vim.fn.termopen(cmd, {
      on_exit = function()
        -- Close only the window this job was started in, and only if it is still
        -- the one `termwin` refers to (otherwise a replacement float is open).
        if termwin == mywin then
          termwin = nil
        end
        if vim.api.nvim_win_is_valid(mywin) then
          pcall(vim.api.nvim_win_close, mywin, true)
        end
      end,
    })
    vim.cmd('startinsert')
  end
end

map({ 'n', 'i', 'x', 't', 'v' }, '<C-/>', float_term(vim.o.shell)) -- fish
map({ 'n', 'i', 'x', 't', 'v' }, '<A-B>', float_term('btop'))
if vim.fn.executable('gh-dash') == 1 then
  map({ 'n', 'i', 'x', 't', 'v' }, '<A-G>', float_term('gh dash'))
end
if vim.fn.executable('yazi') == 1 then
  map({ 'n', 'i', 'x', 't', 'v' }, '<A-F>', float_term('yazi'))
end
map({ 'n', 'i' }, '<A-g>', float_term('lazygit'))
if vim.fn.executable('lazygit') == 1 then
  map('n', '<Leader>gg', float_term('lazygit'), { desc = 'Lazygit (float)' })
end

-- Zen / dashboard / scratch (were 'Snacks.zen', 'Snacks.dashboard', 'Snacks.scratch')
local zen_on = false
map({ 'n', 'i' }, '<A-z>', function()
  zen_on = not zen_on
  vim.o.number = not zen_on
  vim.o.relativenumber = not zen_on
  vim.o.cursorcolumn = not zen_on
  vim.o.signcolumn = zen_on and 'no' or 'yes'
  vim.o.scrolloff = zen_on and 0 or 30
end)
map({ 'n', 'i' }, '<A-Z>', function()
  MiniStarter.open()
end)
map({ 'n', 'i' }, '<A-,>', function()
  vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
end)

-- Theme toggles (were 'Snacks' dark/light switching)
local notify_theme = function(msg, icon)
  pcall(function()
    require('mini.notify').notify(msg, 'INFO', { title = '', icon = icon })
  end)
end
map({ 'i', 'n', 'v', 'x', 'o', 't' }, '<M- >', '') -- Disable Alt+Space
map({ 'i', 'n', 'v', 'x', 'o', 't' }, '<A-->', function()
  vim.opt.background = 'dark'
  vim.cmd.colorscheme('randomhue')
  notify_theme("You're now in dark mode", ' ')
end)
map({ 'i', 'n', 'v', 'x', 'o', 't' }, '<A-=>', function()
  vim.opt.background = 'light'
  vim.cmd.colorscheme('randomhue')
  notify_theme("You're now in light mode", ' ')
end)

-- Misc commands
map({ 'n', 'i' }, '<C-9>', '<Cmd>lua MiniSessions.restart()<CR>') -- was ':restart'
map({ 'n', 'i' }, '<A-1>', '<cmd>Nerdy<cr>')
map({ 'n', 'i' }, '<A-2>', '<cmd>Emoji<cr>') -- emoji picker

-- Plugin manager. `<Leader>l` is already the Language group, so this goes on the
-- Alt palette instead; `:Lazy` is provided by 'lazy.nvim' itself, which is
-- always loaded, so a plain mapping is enough (no `keys` trigger in the spec).
map({ 'n', 'i' }, '<A-l>', '<Cmd>Lazy<CR>', { desc = 'Lazy (plugin manager)' })

-- Picker palette (were 'Snacks.picker' mappings) =============================
-- Re-targeted at MiniMax's `:Pick` commands and 'mini.extra' pickers.
local extra_pick = function(name, opts)
  return function()
    local ok, err = pcall(function()
      require('mini.extra').pickers[name](opts or {})
    end)
    if not ok then
      vim.notify(
        'mini.extra picker unavailable: ' .. name .. ' — ' .. tostring(err):match('[^\n]+'),
        vim.log.levels.WARN
      )
    end
  end
end

map({ 'n', 'i' }, '<A-X>', function()
  vim.cmd('Pick diagnostic scope="all"')
end) -- diagnostics
map({ 'n', 'i' }, '<A-x>', function()
  vim.cmd('Pick diagnostic scope="current"')
end) -- buffer diagnostics
map({ 'n', 'i' }, '<A-c>', extra_pick('commands')) -- commands
map({ 'n', 'i' }, "<A-'>", function()
  vim.cmd('Pick grep pattern="<cword>"')
end) -- smart
map({ 'n', 'i' }, '<A-u>', undo_tree) -- undo tree
map({ 'n', 'i' }, '<A-s>', function()
  vim.cmd('Pick lsp scope="document_symbol"')
end) -- lsp_symbols
map({ 'n', 'i' }, '<A-S>', function()
  vim.cmd('Pick lsp scope="workspace_symbol_live"')
end) -- lsp_workspace_symbols
map({ 'n', 'i' }, '<A-y>', function()
  vim.cmd('YankyRingHistory')
end) -- yank history
-- yanky ring cycling (Normal mode only so 'mini.completion' keeps <C-p>/<C-n>)
map('n', '<C-p>', '<Plug>(YankyCycleForward)')
map('n', '<C-n>', '<Plug>(YankyCycleBackward)')
map({ 'n', 'i' }, '<A-h>', function()
  vim.cmd('Pick help')
end) -- help
map({ 'n', 'i' }, '<A-m>', extra_pick('manpages')) -- man
-- Workspace projects (was 'Snacks.picker.projects'); choosing one sets cwd
map({ 'n', 'i' }, '<A-w>', function()
  local root = vim.fn.expand('~/workspace')
  if vim.fn.isdirectory(root) == 0 then
    root = vim.uv.cwd()
  end
  local items = {}
  for _, dir in ipairs(vim.fn.glob(root .. '/*', false, true)) do
    if vim.fn.isdirectory(dir) == 1 then
      table.insert(items, dir)
    end
  end
  table.sort(items)
  require('mini.pick').start({
    source = {
      items = items,
      name = 'Workspace',
      choose = function(item)
        vim.fn.chdir(item)
        pcall(function()
          require('mini.notify').notify('Workspace: ' .. item, 'INFO')
        end)
      end,
    },
  })
end)
map({ 'n', 'i' }, '<A-;>', function()
  vim.cmd('Pick buf_lines scope="all"')
end) -- lines
map({ 'n', 'i' }, '<A-:>', function() -- git log
  local items = vim.fn.systemlist('git log --oneline -100')
  if vim.v.shell_error ~= 0 then
    vim.notify('Not a git repository', vim.log.levels.WARN)
    return
  end
  require('mini.pick').start({
    source = {
      items = items,
      name = 'Git log',
      choose = function(item)
        local sha = item:match('^%S+')
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.systemlist('git show ' .. sha .. ' --no-color'))
        vim.api.nvim_win_set_buf(0, buf)
        vim.bo[buf].filetype = 'diff'
        vim.bo[buf].bufhidden = 'wipe'
      end,
    },
  })
end)
map({ 'n', 'i' }, '<A-H>', function()
  vim.cmd('Pick history scope=":"')
end) -- command history
map({ 'n', 'i' }, '<A-j>', function() -- jumps
  local jl = vim.fn.getjumplist()
  local items = {}
  for _, j in ipairs(jl[1]) do
    local bufnr, lnum, col = j.bufnr, j.lnum, j.col
    if vim.api.nvim_buf_is_valid(bufnr) then
      local line = (vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ''):gsub('%s+', ' '):sub(1, 60)
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
      table.insert(items, {
        nr = bufnr,
        ln = lnum,
        cc = col,
        text = string.format('%4d  %s  │  %s', lnum, name, line),
      })
    end
  end
  require('mini.pick').start({
    source = {
      items = items,
      name = 'Jumps',
      choose = function(item)
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, item.nr)
        pcall(vim.api.nvim_win_set_cursor, win, { item.ln, item.cc })
        vim.cmd('normal! zz')
      end,
    },
  })
end)
map({ 'n', 'i' }, '<A-b>', function()
  vim.cmd('Pick buffers')
end) -- buffers
map({ 'n', 'i' }, '<A-q>', extra_pick('marks')) -- marks
map({ 'n', 'i' }, '<A-C>', extra_pick('colorschemes')) -- colorschemes
map({ 'n', 'i' }, '<A-R>', function()
  vim.lsp.buf.references()
end) -- lsp_references

-- Config-file editing (was <Leader>ti/tk/tm/to/tp/ta in the previous config)
nmap_leader('ti', edit_config_file('init.lua'), 'init.lua')
nmap_leader('tk', edit_config_file('plugin/20_keymaps.lua'), 'Keymaps')
nmap_leader('to', edit_config_file('lua/options.lua'), 'Options')
nmap_leader('tm', edit_config_file('lua/plugins/mini.lua'), 'MINI config')
nmap_leader('tp', edit_config_file('lua/plugins'), 'Plugins specs')
nmap_leader('ta', edit_config_file('lua/options.lua'), 'Autocmds')
