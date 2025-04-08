local wezterm = require 'wezterm'

local config = wezterm.config_builder()
local custom = {}
custom.ansi = {
    '#1d1f21',
    '#bf6b69',
    '#b7bd73',
    '#e9c880',
    '#88a1bb',
    '#ad95b8',
    '#95bdb7',
    '#c5c8c6',
}
custom.cursor_bg = "#ffffff"
custom.cursor_border = '#ffffff'
custom.cursor_fg = '#ffffff'
custom.brights = {
    '#666666',
    '#cd4c52',
    '#bcc95f',
    '#f0c674',
    '#83a5d6',
    '#bc99d4',
    '#83beb1',
    '#eaeaea',
}
custom.background = "#282c34"
custom.foreground = "#ffffff"
custom.selection_bg = "#ffffff"
custom.selection_fg = "#292c33"
custom.tab_bar = {}
custom.tab_bar.background = '#232634'
custom.tab_bar.active_tab = {}
custom.tab_bar.active_tab.bg_color = "#2a2b35"
custom.tab_bar.active_tab.fg_color = "#2a2b35"
custom.tab_bar.inactive_tab = {}
custom.tab_bar.inactive_tab.bg_color = "#22232e"
custom.tab_bar.inactive_tab.fg_color = "#22232e"

config.color_schemes = {
    ["Ghostty"] = custom,
}
config.color_scheme = "Ghostty"
config.enable_scroll_bar = true
config.min_scroll_bar_height = "4cell"
config.enable_wayland = false
config.window_padding = {
    left = 2,
    right = 13,
    top = 0,
    bottom = 0,
}
return config