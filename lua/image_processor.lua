-- ┌───────────────────────────────┐
-- │ image.nvim: safe ImageMagick  │
-- └───────────────────────────────┘
--
-- `image.nvim` probes image files with ImageMagick through `vim.loop.spawn` and
-- reports every failure with `error()` *inside* the spawn callback. Such a
-- callback runs in a libuv context, where no `pcall` can catch the error, so
-- the failure escapes to Neovim as an uncaught "Lua callback: ..." error -- and
-- the editor keeps waiting (`vim.wait(5000, ...)`) for a process that already
-- gave up.
--
-- The trigger in practice is an SVG badge: it carries its logo as a
-- `data:image/svg+xml;base64,...` URI, ImageMagick tries to open that URI as
-- a file, fails, and `image.nvim` raises the failure from the callback.
--
-- Both probes are therefore replaced with synchronous `vim.system` calls. A
-- failure is then an ordinary Lua error, which `image.nvim` already catches
-- around `from_file()`, so the offending image is skipped instead of crashing
-- the editor.

local M = {}

---Keep an ImageMagick error short: the offending path can be a huge data URI.
---@param text string
---@return string
local function trim(text)
  local first = text:gsub('\r', ''):gsub('\n.*', '')
  if #first > 200 then
    return first:sub(1, 200) .. '...'
  end
  return first
end

---Run ImageMagick's `identify` synchronously.
---@param format string ImageMagick format string ('%m', '%wx%h', ...)
---@param path string
---@return string? output
---@return string? error
local function identify(format, path)
  -- ImageMagick 7 needs 'magick identify', ImageMagick 6 a plain 'identify'.
  local args = vim.fn.executable('magick') == 1 and { 'magick', 'identify', '-format', format, path }
    or { 'identify', '-format', format, path }

  local ok, result = pcall(function()
    return vim.system(args, { text = true }):wait()
  end)
  if not ok then
    return nil, tostring(result)
  end
  if result.code ~= 0 then
    return nil, trim(result.stderr or '')
  end
  return result.stdout or '', nil
end

---Make `image.nvim` fail softly when ImageMagick cannot read a file.
---@return boolean patched
function M.harden()
  -- 'vim.system' needs Neovim 0.10+; keep the plugin's own behaviour below.
  if not vim.system then
    return false
  end

  local ok_magick, magick_cli = pcall(require, 'image/processors/magick_cli')
  if not ok_magick then
    return false
  end
  local ok_magic, magic = pcall(require, 'image/utils/magic')
  if not ok_magic then
    return false
  end
  local ok_dims, dimensions = pcall(require, 'image/utils/dimensions')
  if not ok_dims then
    return false
  end

  -- Format detection: sniff the header in pure Lua first and only fall back
  -- to ImageMagick for the formats the sniffer does not know.
  magick_cli.get_format = function(path)
    local detected = magic.detect_format(path)
    if detected then
      return detected
    end

    local out, err = identify('%m', path)
    if not out then
      error(('image.nvim: identify failed for %s%s'):format(path, err ~= '' and (': ' .. err) or ''), 0)
    end
    return (out:gsub('%s+$', '')):lower()
  end

  -- Dimensions: parse the header in pure Lua first (png, jpeg, gif, webp,
  -- avif, ...) and only fall back to ImageMagick for the rest (svg, pdf).
  magick_cli.get_dimensions = function(path)
    local size = dimensions.get_dimensions(path)
    if size then
      return size
    end

    local out, err = identify('%wx%h', path)
    if not out then
      error(('image.nvim: identify failed for %s%s'):format(path, err ~= '' and (': ' .. err) or ''), 0)
    end

    local width, height = out:match('(%d+)x(%d+)')
    if not width or not height then
      error(('image.nvim: identify returned no dimensions for %s'):format(path), 0)
    end
    return { width = tonumber(width), height = tonumber(height) }
  end

  return true
end

return M
