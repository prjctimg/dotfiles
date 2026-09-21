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

-- Many general mappings are created by 'mini.basics'. See 'plugin/30_mini.lua'

-- stylua: ignore start
-- The next part (until `-- stylua: ignore end`) is aligned manually for easier
-- reading. Consider preserving this or remove `-- stylua` lines to autoformat.

-- Leader mappings ============================================================

-- Neovim has the concept of a Leader key (see `:h <Leader>`). It is a configurable
-- key that is primarily used for "workflow" mappings (opposed to text editing).
-- Like "open file explorer", "create scratch buffer", "pick from buffers".
--
-- In 'plugin/10_options.lua' <Leader> is set to <Space>, i.e. press <Space>
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
-- Many of the mappings use 'mini.nvim' modules set up in 'plugin/30_mini.lua'.

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
  { mode = 'n', keys = '<Leader>s', desc = '+Session' },
  { mode = 'n', keys = '<Leader>t', desc = '+Terminal/Config' },
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
-- - All mappings that use `edit_plugin_file` - edit 'plugin/' config files
local edit_plugin_file = function(filename)
  return string.format('<Cmd>edit %s/plugin/%s<CR>', vim.fn.stdpath('config'), filename)
end
local explore_at_file = '<Cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>'
local explore_quickfix = function()
  vim.cmd(vim.fn.getqflist({ winid = true }).winid ~= 0 and 'cclose' or 'copen')
end
local explore_locations = function()
  vim.cmd(vim.fn.getloclist(0, { winid = true }).winid ~= 0 and 'lclose' or 'lopen')
end

nmap_leader('ed', '<Cmd>lua MiniFiles.open()<CR>',          'Directory')
nmap_leader('ef', explore_at_file,                          'File directory')
nmap_leader('ei', '<Cmd>edit $MYVIMRC<CR>',                 'init.lua')
nmap_leader('ek', edit_plugin_file('20_keymaps.lua'),       'Keymaps config')
nmap_leader('em', edit_plugin_file('30_mini.lua'),          'MINI config')
nmap_leader('en', '<Cmd>lua MiniNotify.show_history()<CR>', 'Notifications')
nmap_leader('eo', edit_plugin_file('10_options.lua'),       'Options config')
nmap_leader('ep', edit_plugin_file('40_plugins.lua'),       'Plugins config')
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
nmap_leader('la', '<Cmd>lua vim.lsp.buf.code_action()<CR>',     'Actions')
nmap_leader('ld', '<Cmd>lua vim.diagnostic.open_float()<CR>',   'Diagnostic popup')
nmap_leader('lf', '<Cmd>lua require("conform").format()<CR>',   'Format')
nmap_leader('li', '<Cmd>lua vim.lsp.buf.implementation()<CR>',  'Implementation')
nmap_leader('lh', '<Cmd>lua vim.lsp.buf.hover()<CR>',           'Hover')
nmap_leader('ll', '<Cmd>lua vim.lsp.codelens.run()<CR>',        'Lens')
nmap_leader('lr', '<Cmd>lua vim.lsp.buf.rename()<CR>',          'Rename')
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
local map = function(mode, key, rhs)
  vim.keymap.set(mode, key, rhs, { noremap = false, silent = true })
end

-- General ====================================================================

-- Enter Command-line mode (was Normal mode in the previous config)
map('n', '<C-;>', ':')

-- LSP actions
map({ 'n', 'i' }, '<A-\\>', function() vim.lsp.buf.code_action() end)
map({ 'n', 'i', 'v' }, '<A-r>', function() vim.lsp.buf.rename() end)

-- Find & replace (was 'grug-far' in the previous config)
map({ 'n', 'i' }, '<A-f>', function()
  local grug = require('grug-far')
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
  if not MiniFiles then pcall(require('mini.files').setup) end
  -- Fall back to the working directory for buffers without a real on-disk path
  local name = vim.api.nvim_buf_get_name(0)
  local path = (name ~= '' and vim.fn.filereadable(name) == 1) and name or vim.uv.cwd()
  pcall(function()
    if not MiniFiles.close() then MiniFiles.open(path, false) end
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
    termwin = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      row = row,
      col = col,
      width = width,
      height = height,
      style = 'minimal',
      border = 'rounded',
    })
    vim.bo[buf].buflisted = false
    vim.keymap.set('t', '<ESC>', '<C-\\><C-n>', { buffer = buf })
    vim.fn.termopen(cmd, {
      on_exit = function()
        pcall(vim.api.nvim_win_close, termwin, true)
        termwin = nil
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
map({ 'n', 'i' }, '<A-Z>', function() MiniStarter.open() end)
map({ 'n', 'i' }, '<A-,>', function()
  vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
end)

-- Theme toggles (were 'Snacks' dark/light switching)
local notify_theme = function(msg, icon)
  pcall(function() require('mini.notify').notify(msg, 'INFO', { title = '', icon = icon }) end)
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
map({ 'n', 'i' }, '<A-2>', '<cmd>InsertEmoji<cr>')

-- Picker palette (were 'Snacks.picker' mappings) =============================
-- Re-targeted at MiniMax's `:Pick` commands and 'mini.extra' pickers.
local extra_pick = function(name, opts)
  return function()
    local ok, err = pcall(function() require('mini.extra').pickers[name](opts or {}) end)
    if not ok then
      vim.notify(
        'mini.extra picker unavailable: ' .. name .. ' — ' .. tostring(err):match('[^\n]+'),
        vim.log.levels.WARN
      )
    end
  end
end

map({ 'n', 'i' }, '<A-X>', function() vim.cmd('Pick diagnostic scope="all"') end) -- diagnostics
map({ 'n', 'i' }, '<A-x>', function() vim.cmd('Pick diagnostic scope="current"') end) -- buffer diagnostics
map({ 'n', 'i' }, '<A-c>', extra_pick('commands')) -- commands
map({ 'n', 'i' }, "<A-'>", function() vim.cmd('Pick grep pattern="<cword>"') end) -- smart
map({ 'n', 'i' }, '<A-u>', function() -- undo tree
  local und = vim.fn.undotree()
  local items = {}
  for _, e in ipairs(und.entries or {}) do
    if e.seq > 0 then
      local mark = (e.seq == und.seq_cur) and '▶ ' or (e.newhead and '·  ' or '   ')
      local n = e.changes or 1
      local changes = (n >= 2) and (' (' .. n .. ' changes)') or ''
      local kind = e.save and 'save' or 'undo'
      table.insert(items, {
        id = e.seq,
        text = string.format('%s%s %s%s', mark, os.date('%H:%M:%S', e.time or und.time_cur or 0), kind, changes),
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
      choose = function(item) vim.cmd('undo ' .. item.id) end,
    },
  })
end)
map({ 'n', 'i' }, '<A-s>', function() vim.cmd('Pick lsp scope="document_symbol"') end) -- lsp_symbols
map({ 'n', 'i' }, '<A-S>', function() vim.cmd('Pick lsp scope="workspace_symbol_live"') end) -- lsp_workspace_symbols
map({ 'n', 'i' }, '<A-y>', function() vim.cmd('YankyRingHistory') end) -- yank history
-- yanky ring cycling (Normal mode only so 'mini.completion' keeps <C-p>/<C-n>)
map('n', '<C-p>', '<Plug>(YankyCycleForward)')
map('n', '<C-n>', '<Plug>(YankyCycleBackward)')
map({ 'n', 'i' }, '<A-h>', function() vim.cmd('Pick help') end) -- help
map({ 'n', 'i' }, '<A-m>', extra_pick('manpages')) -- man
-- Workspace projects (was 'Snacks.picker.projects'); choosing one sets cwd
map({ 'n', 'i' }, '<A-w>', function()
  local root = vim.fn.expand('~/workspace')
  if vim.fn.isdirectory(root) == 0 then root = vim.uv.cwd() end
  local items = {}
  for _, dir in ipairs(vim.fn.glob(root .. '/*', false, true)) do
    if vim.fn.isdirectory(dir) == 1 then table.insert(items, dir) end
  end
  table.sort(items)
  require('mini.pick').start({
    source = {
      items = items,
      name = 'Workspace',
      choose = function(item)
        vim.fn.chdir(item)
        pcall(function() require('mini.notify').notify('Workspace: ' .. item, 'INFO') end)
      end,
    },
  })
end)
map({ 'n', 'i' }, '<A-;>', function() vim.cmd('Pick buf_lines scope="all"') end) -- lines
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
map({ 'n', 'i' }, '<A-H>', function() vim.cmd('Pick history scope=":"') end) -- command history
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
map({ 'n', 'i' }, '<A-b>', function() vim.cmd('Pick buffers') end) -- buffers
map({ 'n', 'i' }, '<A-q>', extra_pick('marks')) -- marks
map({ 'n', 'i' }, '<A-C>', extra_pick('colorschemes')) -- colorschemes
map({ 'n', 'i' }, '<A-R>', function() vim.lsp.buf.references() end) -- lsp_references

-- Config-file editing (was <Leader>ti/tk/tm/to/tp/ta in the previous config)
local cfg_file = function(filename)
  return string.format('<Cmd>edit %s/%s<CR>', vim.fn.stdpath('config'), filename)
end
nmap_leader('ti', cfg_file('init.lua'),              'init.lua')
nmap_leader('tk', cfg_file('plugin/20_keymaps.lua'), 'Keymaps')
nmap_leader('to', cfg_file('plugin/10_options.lua'), 'Options')
nmap_leader('tm', cfg_file('plugin/30_mini.lua'),    'MINI config')
nmap_leader('tp', cfg_file('plugin/40_plugins.lua'), 'Plugins')
nmap_leader('ta', cfg_file('plugin/10_options.lua'), 'Autocmds')
