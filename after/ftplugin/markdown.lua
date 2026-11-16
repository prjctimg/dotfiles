-- ┌─────────────────────────┐
-- │ Markdown filetype config │
-- └─────────────────────────┘

-- Enable spelling and wrap for window
vim.cmd('setlocal spell wrap')

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

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end
local function valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function close_preview()
  if valid_win(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  if valid_buf(state.buf) then
    pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
  end
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
    pcall(function() vim.bo[state.buf].filetype = vim.bo[src_buf].filetype end)
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
  vim.wo[win].cursorline = false

  state.buf, state.win = preview_buf, win
  vim.b[src_buf].md_float_preview_state = state
  sync_preview()

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = aug,
    buffer = preview_buf,
    once = true,
    callback = function()
      if state.buf == preview_buf then
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
