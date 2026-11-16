-- ┌─────────────────────────┐
-- │ Markdown filetype config │
-- └─────────────────────────┘

-- Enable spelling and soft wrapping for prose
vim.cmd('setlocal spell wrap linebreak breakindent')

-- Fold with tree-sitter
vim.cmd('setlocal foldmethod=expr foldexpr=v:lua.vim.treesitter.foldexpr()')

-- Disable built-in `gO` mapping in favor of 'mini.basics'.
if vim.fn.maparg('gO', 'n', false, true) ~= '' then
  pcall(vim.keymap.del, 'n', 'gO', { buffer = 0 })
end

-- Set markdown-specific surrounding in 'mini.surround'
vim.b.minisurround_config = {
  custom_surroundings = {
    -- Markdown link. Common usage:
    -- `saiwL` + [type/paste link] + <CR> - add link
    -- `sdL` - delete link
    -- `srLL` + [type/paste link] + <CR> - replace link
    L = {
      input = { '%[().-()%]%(.-%)' },
      output = function()
        local link = require('mini.surround').user_input('Link: ')
        return { left = '[', right = '](' .. link .. ')' }
      end,
    },
  },
}

-- Floating rendered preview while editing (powered by render-markdown.nvim).
-- Opens on InsertEnter and closes on InsertLeave for markdown buffers.
local src_buf = vim.api.nvim_get_current_buf()
if vim.b[src_buf].md_float_preview_setup then
  return
end
vim.b[src_buf].md_float_preview_setup = true

local state = vim.b[src_buf].md_float_preview_state or { win = nil, buf = nil }
vim.b[src_buf].md_float_preview_state = state
local aug = vim.api.nvim_create_augroup('md-float-preview-' .. src_buf, { clear = true })
local ns = vim.api.nvim_create_namespace('md-float-preview-cursor-' .. src_buf)
local saved_edit_opts = nil
local wrap_limit = nil
local enforcing_wrap = false

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end
local function valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function source_edit_win()
  for _, win in ipairs(vim.fn.win_findbuf(src_buf)) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative == '' then return win end
    end
  end
  local cur = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(cur) and vim.api.nvim_win_get_buf(cur) == src_buf then
    return cur
  end
  return nil
end

local function preview_left_col()
  if not valid_win(state.win) then return nil end
  local ok, cfg = pcall(vim.api.nvim_win_get_config, state.win)
  if not ok or type(cfg) ~= 'table' then return nil end
  local c = cfg.col
  if type(c) == 'number' then return c end
  if type(c) == 'table' then return c[false] or c[1] end
  return nil
end

local function compute_edit_width(preview_col)
  local src_win = source_edit_win()
  local pcol = preview_col or preview_left_col()
  if not src_win then
    return math.max(20, (pcol or (vim.o.columns - 40)) - 4)
  end
  local win_pos = vim.api.nvim_win_get_position(src_win) -- {row, col} in editor
  local win_width = vim.api.nvim_win_get_width(src_win)
  local info = vim.fn.getwininfo(src_win)[1] or {}
  local textoff = info.textoff or 0
  local available = win_width - textoff - 2
  if pcol then
    local overlap = math.max(0, (win_pos[2] + win_width) - pcol)
    available = win_width - textoff - overlap - 2
  end
  return math.max(20, available)
end

local function in_fenced_code(line_nr)
  -- Best-effort: treat lines inside ``` fences as code (skip hard-wrap guard).
  local ok, lines = pcall(vim.api.nvim_buf_get_lines, src_buf, 0, line_nr, false)
  if not ok then return false end
  local fence = false
  for _, l in ipairs(lines) do
    if l:match('^%s*```') or l:match('^%s*~~~') then
      fence = not fence
    end
  end
  return fence
end

local function enforce_wrap_guard()
  if enforcing_wrap or not valid_win(state.win) or not valid_buf(src_buf) then return end
  if not wrap_limit or wrap_limit < 20 then return end
  local mode = vim.api.nvim_get_mode().mode
  if not mode:match('^i') and not mode:match('^R') then return end
  local src_win = source_edit_win()
  if not src_win or vim.api.nvim_get_current_win() ~= src_win then return end

  local ok_cur, cur = pcall(vim.api.nvim_win_get_cursor, src_win)
  if not ok_cur then return end
  local row, col = cur[1], cur[2] -- 1-based row, 0-based byte col
  local line = vim.api.nvim_buf_get_lines(src_buf, row - 1, row, false)[1] or ''
  if #line == 0 then return end
  if in_fenced_code(row) then return end

  local ok_vc, vcol = pcall(vim.fn.virtcol, { row, col + 1 })
  if not ok_vc then return end
  if vcol <= wrap_limit + 1 then return end

  -- Find last whitespace break point at or before limit (display columns).
  local break_byte = nil
  local i = 1
  local disp = 0
  while i <= #line do
    local chlen = 1
    local b = line:byte(i)
    if b then
      if b >= 240 then chlen = 4 elseif b >= 224 then chlen = 3 elseif b >= 192 then chlen = 2 end
    end
    local ch = line:sub(i, i + chlen - 1)
    local w = vim.fn.strdisplaywidth(ch)
    if disp + w > wrap_limit then break end
    disp = disp + w
    local next_i = i + chlen
    if ch:match('%s') and next_i - 1 < col then
      break_byte = i -- byte index (1-based) of whitespace char
    end
    i = next_i
  end
  if not break_byte then return end
  -- avoid breaking too early or in indentation-only area
  local prefix = line:sub(1, break_byte - 1)
  if prefix:match('^%s*$') then return end

  enforcing_wrap = true
  local ok_mod = pcall(function()
    local before = line:sub(1, break_byte - 1):gsub('%s+$', '')
    local after = line:sub(break_byte):gsub('^%s+', '')
    vim.api.nvim_buf_set_lines(src_buf, row - 1, row, false, { before, after })
    local new_row = row + 1
    local new_col = math.min(col - break_byte, #after)
    if new_col < 0 then new_col = #after end
    pcall(vim.api.nvim_win_set_cursor, src_win, { new_row, new_col })
  end)
  enforcing_wrap = false
  if ok_mod then
    -- keep preview/text state in sync
    pcall(sync_preview)
  end
end

local function apply_edit_wrap(preview_col)
  if not valid_buf(src_buf) then return end
  if not saved_edit_opts then
    saved_edit_opts = {
      textwidth = vim.bo[src_buf].textwidth,
      formatoptions = vim.bo[src_buf].formatoptions,
    }
  end
  local tw = compute_edit_width(preview_col)
  wrap_limit = tw
  vim.bo[src_buf].textwidth = tw
  local fo = vim.bo[src_buf].formatoptions
  -- Ensure auto-wrap while typing; keep 'l' off so long lines can be wrapped.
  if not fo:find('t', 1, true) then fo = fo .. 't' end
  fo = fo:gsub('l', '')
  vim.bo[src_buf].formatoptions = fo
end

local function restore_edit_wrap()
  if not saved_edit_opts then return end
  if valid_buf(src_buf) then
    vim.bo[src_buf].textwidth = saved_edit_opts.textwidth
    vim.bo[src_buf].formatoptions = saved_edit_opts.formatoptions
  end
  saved_edit_opts = nil
  wrap_limit = nil
end

local function set_source_rendering(enabled)
  pcall(function()
    require('render-markdown.core.manager').set_buf(src_buf, enabled)
  end)
end

local function close_preview()
  if valid_win(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  if valid_buf(state.buf) then
    pcall(vim.api.nvim_buf_clear_namespace, state.buf, ns, 0, -1)
    pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
  end
  set_source_rendering(true)
  restore_edit_wrap()
  state.win, state.buf = nil, nil
  vim.b[src_buf].md_float_preview_state = state
end

local function sync_cursor()
  if not (valid_buf(src_buf) and valid_win(state.win) and valid_buf(state.buf)) then
    return
  end
  local ok, pos = pcall(vim.api.nvim_win_get_cursor, 0)
  if not ok or type(pos) ~= 'table' then
    return
  end
  local line_count = vim.api.nvim_buf_line_count(state.buf)
  local line = math.max(1, math.min(pos[1], math.max(1, line_count)))
  local target_line = vim.api.nvim_buf_get_lines(state.buf, line - 1, line, false)[1] or ''
  local col = math.max(0, math.min(pos[2], #target_line))
  pcall(vim.api.nvim_win_set_cursor, state.win, { line, col })
  pcall(vim.api.nvim_buf_clear_namespace, state.buf, ns, 0, -1)
  pcall(vim.api.nvim_buf_set_extmark, state.buf, ns, line - 1, 0, {
    end_row = line,
    hl_group = 'CursorLine',
    hl_eol = true,
    priority = 200,
  })
  pcall(vim.api.nvim_buf_set_extmark, state.buf, ns, line - 1, 0, {
    virt_text = { { '▌ ', 'Special' } },
    virt_text_pos = 'overlay',
    priority = 210,
  })
  pcall(vim.api.nvim_win_call, state.win, function()
    vim.cmd('normal! zz')
  end)
end

local function sync_preview()
  if not (valid_buf(src_buf) and valid_buf(state.buf)) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(src_buf, 0, -1, false)
  vim.bo[state.buf].modifiable = true
  pcall(vim.api.nvim_buf_set_lines, state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  if vim.bo[state.buf].filetype ~= vim.bo[src_buf].filetype then
    pcall(function()
      vim.bo[state.buf].filetype = vim.bo[src_buf].filetype
    end)
  end
  pcall(function()
    require('render-markdown').render({ buf = state.buf })
  end)
  sync_cursor()
end

local function open_preview()
  if not valid_buf(src_buf) then
    return
  end
  if vim.bo[src_buf].filetype ~= 'markdown' and vim.bo[src_buf].filetype ~= 'mdx' then
    return
  end
  if valid_win(state.win) and valid_buf(state.buf) then
    set_source_rendering(false)
    local cfg = vim.api.nvim_win_get_config(state.win)
    local preview_col = type(cfg.col) == 'number' and cfg.col or (type(cfg.col) == 'table' and cfg.col[false] or nil)
    apply_edit_wrap(preview_col)
    sync_preview()
    return
  end

  local preview_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[preview_buf].buftype = 'nofile'
  vim.bo[preview_buf].bufhidden = 'wipe'
  vim.bo[preview_buf].swapfile = false
  vim.bo[preview_buf].modifiable = false
  vim.bo[preview_buf].filetype = vim.bo[src_buf].filetype

  local width = math.max(40, math.floor(vim.o.columns * 0.45))
  local height = math.max(10, math.floor(vim.o.lines * 0.6))
  local row = math.max(1, math.floor((vim.o.lines - height) / 2 - 1))
  local col = math.max(1, vim.o.columns - width - 2)

  -- Wrap source text before it runs behind the floating preview.
  apply_edit_wrap(col)

  local win = vim.api.nvim_open_win(preview_buf, false, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'single',
    title = ' Markdown Preview ',
    title_pos = 'center',
    focusable = false,
    noautocmd = true,
  })

  vim.wo[win].wrap = true
  vim.wo[win].conceallevel = 2
  vim.wo[win].concealcursor = 'n'
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].cursorline = true
  vim.wo[win].cursorlineopt = 'line'
  vim.wo[win].winhighlight = 'CursorLine:IncSearch'

  state.buf, state.win = preview_buf, win
  vim.b[src_buf].md_float_preview_state = state
  set_source_rendering(false)
  sync_preview()

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = aug,
    buffer = preview_buf,
    once = true,
    callback = function()
      if state.buf == preview_buf then
        set_source_rendering(true)
        restore_edit_wrap()
        state.buf, state.win = nil, nil
        vim.b[src_buf].md_float_preview_state = state
      end
    end,
  })
end

vim.api.nvim_create_autocmd('InsertEnter', {
  group = aug,
  buffer = src_buf,
  callback = function()
    vim.schedule(function()
      open_preview()
      sync_preview()
    end)
  end,
  desc = 'Open floating markdown preview while editing',
})

vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave', 'BufWipeout' }, {
  group = aug,
  buffer = src_buf,
  callback = function(ev)
    if ev.event == 'InsertLeave' or ev.event == 'BufLeave' or ev.event == 'BufWipeout' then
      close_preview()
    end
  end,
  desc = 'Close floating markdown preview when leaving edit mode',
})

vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged', 'TextChangedP' }, {
  group = aug,
  buffer = src_buf,
  callback = function()
    if valid_win(state.win) and valid_buf(state.buf) then
      if not enforcing_wrap then
        enforce_wrap_guard()
      end
      vim.schedule(sync_preview)
    end
  end,
  desc = 'Sync floating markdown preview content live',
})

vim.api.nvim_create_autocmd({ 'CursorMovedI', 'CursorMoved' }, {
  group = aug,
  buffer = src_buf,
  callback = function()
    if valid_win(state.win) and valid_buf(state.buf) then
      vim.schedule(sync_cursor)
    end
  end,
  desc = 'Sync floating markdown preview cursor position',
})

-- when preview is active and layout changes, recompute wrap boundary
vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
  group = aug,
  callback = function()
    if valid_win(state.win) and valid_buf(src_buf) then
      apply_edit_wrap(preview_left_col())
      vim.schedule(sync_preview)
    end
  end,
  desc = 'Recompute markdown preview wrap boundary on resize',
})
