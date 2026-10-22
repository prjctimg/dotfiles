-- ┌──────────────────┐
-- │ Path completion │
-- └──────────────────┘
--
-- Neovim's built-in insert completion has no notion of a file path: `'complete'`
-- only lists sources that scan text (buffers, dictionaries, spell), and the
-- start position of a match is derived from |'iskeyword'|, which deliberately
-- does not contain `/`, `.` or `~`. So typing `./init` in a Lua file completes
-- nothing at all.
--
-- Neovim 0.11+ works around this with the `F{func}` flag of `'complete'`
-- (`:h 'complete'`), the one source kind allowed to start at a non-keyword
-- character. This module provides that source: it locates the path token under
-- the cursor and returns the entries of the directory that token points at.
--
-- Because it is a 'complete' source rather than a separate mapping, it works in
-- every filetype and merges with whatever else is in the popup -- including the
-- LSP candidates shown by 'mini.completion'.
--
-- It is registered in 'lua/options.lua'.

local M = {}

-- Characters that may legally appear inside a path. They define the extent of
-- the token being completed, i.e. how far back to scan from the cursor. `-` and
-- `.` are here so `my-file.lua`, `./x` and `../x` stay one token; `~` and `$`
-- are here so `~/notes` and `$XDG_CONFIG_HOME/nvim` are scanned as a single
-- leading component instead of being cut at the `~` or `$`.
local function is_path_char(char)
  return char:match('[%w%._/%-~%$%+:@\\]') ~= nil
end

-- Whether `token` is shaped like a path at all. This is what keeps the source
-- quiet: bare words are left to keyword completion, so typing `foo` never pops
-- up a directory listing and `<C-n>` stays fast while writing ordinary code.
local function looks_like_path(token)
  if token:find('/', 1, true) then
    return true
  end
  if token:match('^~') or token:match('^%.') then
    return true
  end -- ~, ~/…, ./…, ../…
  return token:find('$', 1, true) ~= nil -- $VAR/…
end

--- Byte index (1-based) where the path token before the cursor starts.
--- Returns -1 to signal "this is not a path, contribute nothing", which is
--- what |complete-functions| expects to opt out of a match.
---@return number
function M.path_start()
  local line = vim.api.nvim_get_current_line()
  -- `nvim_win_get_cursor` gives a 0-based *byte* index of the character under
  -- the cursor, so slicing up to it yields exactly the text before the cursor.
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)

  local i = col
  while i > 0 and is_path_char(before:sub(i, i)) do
    i = i - 1
  end

  local start = i + 1
  if not looks_like_path(before:sub(start)) then
    return -1
  end
  return start
end

-- Split `base` into the directory to list (expanded, so `~` and `$VAR` work)
-- and the prefix entries must start with. `raw_dir` is the unexpanded directory
-- part, kept because that is what has to be *inserted*: expanding `~/` to
-- `/home/you/` would rewrite the line.
---@return string|nil raw_dir, string dir, string stem
function M.split_base(base)
  -- Everything up to and including the last separator is the directory; the
  -- rest is the partial name. With no separator the working directory is meant.
  local sep = base:find('/[^/]*$')
  local raw_dir, stem = '', base
  if sep then
    raw_dir, stem = base:sub(1, sep), base:sub(sep + 1)
  end

  -- An empty prefix means "here", and `~`/`$VAR` only expand in a non-empty
  -- string; `''` therefore has to become '.' explicitly.
  local dir = raw_dir ~= '' and vim.fn.expand(raw_dir) or '.'
  if dir == nil or vim.fn.isdirectory(dir) ~= 1 then
    return nil
  end

  return raw_dir, dir, stem
end

--- |complete-functions| implementation. Used as the `F` source of 'complete'.
---@param findstart number Non-zero for the "where does the match start" call
---@param base string Text from the start position up to the cursor
---@return number|string[] #
function M.path_complete(findstart, base)
  if findstart == 1 then
    return M.path_start()
  end

  local raw_dir, dir, stem = M.split_base(base)
  if not raw_dir then
    return {}
  end

  -- `dir` may or may not already end in a separator (`./` vs `.`), so join
  -- explicitly rather than assuming one of the two shapes.
  local join = function(a, b)
    return (a:sub(-1) == '/' or a == '') and a .. b or a .. '/' .. b
  end

  local items = {}
  -- Sort so the order does not depend on the filesystem, and hide dotfiles
  -- while the prefix is still empty: listing a project root should not surface
  -- `.git` internals, while `.` and `..` still reach them.
  local names = vim.fn.readdir(dir)
  table.sort(names)
  for _, name in ipairs(names) do
    if name:sub(1, #stem) == stem and (stem ~= '' or name:sub(1, 1) ~= '.') then
      local text = raw_dir .. name
      if vim.fn.isdirectory(join(dir, name)) == 1 then
        -- Trailing separator so a directory can be accepted and typed straight
        -- on into the next component.
        items[#items + 1] = { word = text .. '/', menu = '[dir]' }
      else
        items[#items + 1] = { word = text, menu = '[file]' }
      end
    end
  end

  return items
end

return M
