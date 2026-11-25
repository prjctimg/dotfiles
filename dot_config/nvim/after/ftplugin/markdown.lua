-- ┌─────────────────────────┐
-- │ Markdown filetype config │
-- └─────────────────────────┘

-- Enable spelling and wrapping for prose. Keep lines <= 80 chars.
vim.cmd('setlocal spell wrap linebreak breakindent textwidth=80 colorcolumn=')
do
  local fo = vim.bo.formatoptions
  if not fo:find('t', 1, true) then fo = fo .. 't' end
  fo = fo:gsub('l', '')
  vim.bo.formatoptions = fo
end

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

-- Rendered preview in a split while editing (powered by render-markdown.nvim).
-- Opens when entering insert mode via `o` and closes on InsertLeave for markdown buffers.
local src_buf = vim.api.nvim_get_current_buf()
if vim.b[src_buf].md_split_preview_setup then
  return
end
vim.b[src_buf].md_split_preview_setup = true

local state = vim.b[src_buf].md_split_preview_state or { win = nil, buf = nil }
vim.b[src_buf].md_split_preview_state = state
local aug = vim.api.nvim_create_augroup('md-split-preview-' .. src_buf, { clear = true })
local ns = vim.api.nvim_create_namespace('md-split-preview-cursor-' .. src_buf)
local open_via_o = false
local saved_edit_opts = nil
local wrap_limit = nil
local enforcing_wrap = false
local sync_preview, sync_cursor

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

local function compute_edit_width()
  local src_win = source_edit_win()
  if not src_win then
    return math.max(20, math.floor(vim.o.columns * 0.5) - 4)
  end
  local win_width = vim.api.nvim_win_get_width(src_win)
  local info = vim.fn.getwininfo(src_win)[1] or {}
  local textoff = info.textoff or 0
  return math.max(20, win_width - textoff - 2)
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
  if enforcing_wrap or not valid_buf(src_buf) then return end
  if not wrap_limit or wrap_limit < 20 then return end
  local mode = vim.api.nvim_get_mode().mode
  if not mode:match('^i') and not mode:match('^R') then return end
  local src_win = source_edit_win()
  if not src_win or vim.api.nvim_get_current_win() ~= src_win then return end

  local ok_cur, cur = pcall(vim.api.nvim_win_get_cursor, src_win)
  if not ok_cur then return end
  local row, col = cur[1], cur[2] -- 1-based row, 0-based byte col
  local line = vim.api.nvim_buf_get_lines(src_buf, row - 1, row, false)[1] or ''
  if vim.fn.strdisplaywidth(line) <= wrap_limit then return end
  if in_fenced_code(row) then return end

  -- Build break points by display width.
  local chars = {} -- {byte_start(1-based), byte_end(1-based), disp_end, is_space}
  local i = 1
  local disp = 0
  while i <= #line do
    local chlen = 1
    local b = line:byte(i)
    if b then
      if b >= 240 then chlen = 4 elseif b >= 224 then chlen = 3 elseif b >= 192 then chlen = 2 end
    end
    local j = i + chlen - 1
    local ch = line:sub(i, j)
    local w = vim.fn.strdisplaywidth(ch)
    disp = disp + w
    chars[#chars + 1] = { i, j, disp, ch:match('%s') ~= nil }
    i = j + 1
  end
  if #chars == 0 then return end

  -- Prefer last whitespace at/before limit and before cursor.
  local break_idx = nil
  for idx, c in ipairs(chars) do
    if c[3] > wrap_limit then break end
    if c[4] and c[2] < col then break_idx = idx end
  end
  -- Force break at limit if no suitable whitespace (hard wrap).
  if not break_idx then
    for idx, c in ipairs(chars) do
      if c[3] > wrap_limit then
        break_idx = math.max(1, idx - 1)
        break
      end
    end
  end
  if not break_idx or break_idx < 1 then break_idx = #chars end

  local split_at = chars[break_idx][2] -- byte end of break char
  local before = line:sub(1, split_at)
  local after = line:sub(split_at + 1)
  local break_is_space = chars[break_idx][4]
  if break_is_space then
    before = before:gsub('%s+$', '')
    after = after:gsub('^%s+', '')
  end
  if before == line or (before:match('^%s*$') and not break_is_space) then return end

  -- Keep indentation for wrapped continuation when breaking on whitespace.
  if break_is_space and not after:match('^%s') then
    local indent = line:match('^(%s*)') or ''
    -- avoid duplicating list markers crudely; basic indent carry-over is safer
    if indent ~= '' and not indent:match('[%-%*%+%>%d]') then
      after = indent .. after
    end
  end

  enforcing_wrap = true
  local ok_mod = pcall(function()
    vim.api.nvim_buf_set_lines(src_buf, row - 1, row, false, { before, after })
    local new_row = row + 1
    if col <= split_at then
      -- cursor was at/before split: keep on first line (clamped)
      pcall(vim.api.nvim_win_set_cursor, src_win, { row, math.min(col, #before) })
    else
      local moved = col - split_at
      local delta = #after - (#line - split_at)
      local new_col = moved + delta
      if new_col < 0 then new_col = 0 end
      if new_col > #after then new_col = #after end
      pcall(vim.api.nvim_win_set_cursor, src_win, { new_row, new_col })
    end
  end)
  enforcing_wrap = false
  if ok_mod and valid_buf(state.buf) then
    vim.schedule(sync_preview)
  end
end

local function apply_edit_wrap()
  if not valid_buf(src_buf) then return end
  if not saved_edit_opts then
    saved_edit_opts = {
      textwidth = vim.bo[src_buf].textwidth,
      formatoptions = vim.bo[src_buf].formatoptions,
    }
  end
  local tw = math.min(80, compute_edit_width())
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
  open_via_o = false
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
  vim.b[src_buf].md_split_preview_state = state
end

sync_cursor = function()
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

sync_preview = function()
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
    apply_edit_wrap()
    sync_preview()
    return
  end

  local src_win = source_edit_win()
  local preview_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[preview_buf].buftype = 'nofile'
  vim.bo[preview_buf].bufhidden = 'wipe'
  vim.bo[preview_buf].swapfile = false
  vim.bo[preview_buf].modifiable = false
  vim.bo[preview_buf].filetype = vim.bo[src_buf].filetype

  local height = math.max(10, math.floor(vim.o.lines * 0.35))
  local win = vim.api.nvim_open_win(preview_buf, false, {
    split = 'below',
    win = src_win or 0,
  })
  pcall(vim.api.nvim_win_set_height, win, height)

  vim.wo[win].wrap = true
  vim.wo[win].conceallevel = 2
  vim.wo[win].concealcursor = 'n'
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].cursorline = true
  vim.wo[win].cursorlineopt = 'line'
  vim.wo[win].winhighlight = 'CursorLine:IncSearch'
  vim.wo[win].winfixheight = true

  -- Recompute wrap for the editor window beside the preview split.
  apply_edit_wrap()

  state.buf, state.win = preview_buf, win
  vim.b[src_buf].md_split_preview_state = state
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
        vim.b[src_buf].md_split_preview_state = state
      end
    end,
  })
end

vim.keymap.set('n', 'o', function()
  open_via_o = true
  return 'o'
end, { buffer = src_buf, expr = true, silent = true, desc = 'Open line below and show markdown preview' })

vim.api.nvim_create_autocmd('InsertEnter', {
  group = aug,
  buffer = src_buf,
  callback = function()
    if not open_via_o then return end
    open_via_o = false
    vim.schedule(function()
      if valid_buf(src_buf) and vim.api.nvim_get_mode().mode:match('^i') then
        open_preview()
        sync_preview()
      end
    end)
  end,
  desc = 'Open markdown preview split when entering insert mode via o',
})

vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave', 'BufWipeout' }, {
  group = aug,
  buffer = src_buf,
  callback = function(ev)
    if ev.event == 'InsertLeave' or ev.event == 'BufLeave' or ev.event == 'BufWipeout' then
      close_preview()
    end
  end,
  desc = 'Close markdown preview split when leaving edit mode',
})

vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChangedP' }, {
  group = aug,
  buffer = src_buf,
  callback = function()
    if valid_buf(src_buf) then
      if not enforcing_wrap then
        enforce_wrap_guard()
      end
      if valid_win(state.win) and valid_buf(state.buf) then
        vim.schedule(sync_preview)
      end
    end
  end,
  desc = 'Enforce markdown wrap and sync preview split live',
})

vim.api.nvim_create_autocmd({ 'CursorMovedI', 'CursorMoved' }, {
  group = aug,
  buffer = src_buf,
  callback = function()
    if valid_win(state.win) and valid_buf(state.buf) then
      vim.schedule(sync_cursor)
    end
  end,
  desc = 'Sync markdown preview split cursor position',
})

-- when preview is active and layout changes, recompute wrap boundary
vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
  group = aug,
  callback = function()
    if valid_win(state.win) and valid_buf(src_buf) then
      apply_edit_wrap()
      vim.schedule(sync_preview)
    end
  end,
  desc = 'Recompute markdown preview wrap boundary on resize',
})
