local wezterm = require("wezterm")
local M = {}

local LAT, LON = -17.8, 31.0
local THEME_FILE = "/tmp/wez-theme"

local theme = {
  day = "tokyonight_day",
  night = "tokyonight_night",
  storm = "tokyonight_storm",
}

local function to_epoch(time_obj)
  return tonumber(time_obj:format("%s"))
end

local function detect_theme()
  local now = wezterm.time.now()
  local sun = now:sun_times(LAT, LON)

  local now_epoch = to_epoch(now)
  local rise_epoch = to_epoch(sun.rise)
  local set_epoch = to_epoch(sun.set)

  local one_hour = 3600

  if now_epoch >= rise_epoch and now_epoch < set_epoch - one_hour then
    return "day"
  elseif now_epoch >= set_epoch - one_hour and now_epoch < set_epoch + one_hour then
    return "storm"
  else
    return "night"
  end
end

function M.setup(config)
  local mode = detect_theme()
  local colorscheme = theme[mode]

  config.color_scheme = colorscheme

  local f = io.open(THEME_FILE, "w")
  if f then
    f:write(mode)
    f:close()
  end
end

return M
