local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end



-- 'JetBrains Mono' is not an installed family -- fc-match falls through to
-- Noto Sans, a proportional face, so every Private Use Area codepoint the apps
-- draw landed on font fallback instead of a glyph. The Nerd Font is installed,
-- under the name 'JetBrains Mono Nerd Font'.
config.font = wezterm.font_with_fallback({
  { family = 'JetBrains Mono Nerd Font', weight = 'Medium' },
})

config.font_size = 12

config.default_prog = { 'fish' }

config.keys = {
  { key = 'T', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'W', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab { confirm = true } },
  { key = 'O', mods = 'CTRL|SHIFT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'E', mods = 'CTRL|SHIFT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'LeftArrow', mods = 'CTRL|ALT', action = wezterm.action.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'CTRL|ALT', action = wezterm.action.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'CTRL|ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CTRL|ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
  { key = 'LeftBracket', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  { key = 'RightBracket', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(1) },
  { key = '{', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  { key = '}', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(1) },
  { key = 'Enter', mods = 'CTRL|SHIFT', action = wezterm.action.TogglePaneZoomState },
  { key = '1', mods = 'CTRL', action = wezterm.action.ActivateTab(0) },
  { key = '2', mods = 'CTRL', action = wezterm.action.ActivateTab(1) },
  { key = '3', mods = 'CTRL', action = wezterm.action.ActivateTab(2) },
  { key = '4', mods = 'CTRL', action = wezterm.action.ActivateTab(3) },
  { key = '5', mods = 'CTRL', action = wezterm.action.ActivateTab(4) },
  { key = '6', mods = 'CTRL', action = wezterm.action.ActivateTab(5) },
  { key = '7', mods = 'CTRL', action = wezterm.action.ActivateTab(6) },
  { key = '8', mods = 'CTRL', action = wezterm.action.ActivateTab(7) },
  { key = '9', mods = 'CTRL', action = wezterm.action.ActivateTab(8) },
}

config.window_background_image = wezterm.home_dir .. "/.config/wallpaper.jpg"
config.window_background_image_hsb = {
  brightness = 0.05,
  hue = 1.0,
  saturation = 1.0,
}

require("theme").setup(config)
config.enable_wayland = false
return config
