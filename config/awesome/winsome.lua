winsome = {}

winsome.shared_dir = "/usr/share/awesome/"
winsome.default_dir = winsome.shared_dir .. "themes/default/"

winsome.theme = function(name)
  local theme = {}
  theme.name = name

  -- We assume themes will be installed as ~/.config/awesome/themes/theme_name
  theme.dir = awful.util.getdir("config") .. "/themes/" .. theme.name .. "/"
  theme.shared_dir = winsome.shared_dir
  theme.default_dir = winsome.default_dir

  theme.wallpaper_cmd = { "awsetbg -a -r " .. theme.dir .. "backgrounds" }

  return awful.util.table.join(theme, winsome.defaults)
end

winsome.defaults = {}
winsome.defaults.font = "sans 8"

winsome.defaults.bg_normal     = "#FFFFFF"
winsome.defaults.bg_focus      = "#AAAAAA"
winsome.defaults.bg_urgent     = "#FFAAAA"
winsome.defaults.bg_minimize   = "#666666"

winsome.defaults.fg_normal     = "#000000"
winsome.defaults.fg_focus      = "#000000"
winsome.defaults.fg_urgent     = "#000000"
winsome.defaults.fg_minimize   = "#000000"

winsome.defaults.border_width  = "1"
winsome.defaults.border_normal = "#444444"
winsome.defaults.border_focus  = "#000000"
winsome.defaults.border_marked = "#005500"

winsome.defaults.taglist_squares_sel = winsome.default_dir .. "taglist/squarefw.png"
winsome.defaults.taglist_squares_unsel = winsome.default_dir .. "taglist/squarew.png"

winsome.defaults.tasklist_floating_icon = winsome.default_dir .. "tasklist/floatingw.png"

winsome.defaults.menu_submenu_icon = winsome.default_dir .. "submenu.png"
winsome.defaults.menu_height   = "15"
winsome.defaults.menu_width    = "100"

winsome.defaults.titlebar_close_button_normal = winsome.default_dir .. "titlebar/close_normal.png"
winsome.defaults.titlebar_close_button_focus = winsome.default_dir .. "titlebar/close_focus.png"

winsome.defaults.titlebar_ontop_button_normal_inactive = winsome.default_dir .. "titlebar/ontop_normal_inactive.png"
winsome.defaults.titlebar_ontop_button_focus_inactive = winsome.default_dir .. "titlebar/ontop_focus_inactive.png"
winsome.defaults.titlebar_ontop_button_normal_active = winsome.default_dir .. "titlebar/ontop_normal_active.png"
winsome.defaults.titlebar_ontop_button_focus_active = winsome.default_dir .. "titlebar/ontop_focus_active.png"

winsome.defaults.titlebar_sticky_button_normal_inactive = winsome.default_dir .. "titlebar/sticky_normal_inactive.png"
winsome.defaults.titlebar_sticky_button_focus_inactive = winsome.default_dir .. "titlebar/sticky_focus_inactive.png"
winsome.defaults.titlebar_sticky_button_normal_active = winsome.default_dir .. "titlebar/sticky_normal_active.png"
winsome.defaults.titlebar_sticky_button_focus_active = winsome.default_dir .. "titlebar/sticky_focus_active.png"

winsome.defaults.titlebar_floating_button_normal_inactive = winsome.default_dir .. "titlebar/floating_normal_inactive.png"
winsome.defaults.titlebar_floating_button_focus_inactive = winsome.default_dir .. "titlebar/floating_focus_inactive.png"
winsome.defaults.titlebar_floating_button_normal_active = winsome.default_dir .. "titlebar/floating_normal_active.png"
winsome.defaults.titlebar_floating_button_focus_active = winsome.default_dir .. "titlebar/floating_focus_active.png"

winsome.defaults.titlebar_maximized_button_normal_inactive = winsome.default_dir .. "titlebar/maximized_normal_inactive.png"
winsome.defaults.titlebar_maximized_button_focus_inactive = winsome.default_dir .. "titlebar/maximized_focus_inactive.png"
winsome.defaults.titlebar_maximized_button_normal_active = winsome.default_dir .. "titlebar/maximized_normal_active.png"
winsome.defaults.titlebar_maximized_button_focus_active = winsome.default_dir .. "titlebar/maximized_focus_active.png"

winsome.defaults.layouts_dir = winsome.default_dir .. "layouts/"
winsome.defaults.layout_fairh = winsome.defaults.layouts_dir .. "fairhw.png"
winsome.defaults.layout_fairv = winsome.defaults.layouts_dir .. "fairvw.png"
winsome.defaults.layout_floating = winsome.defaults.layouts_dir .. "floatingw.png"
winsome.defaults.layout_magnifier = winsome.defaults.layouts_dir .. "magnifierw.png"
winsome.defaults.layout_max = winsome.defaults.layouts_dir .. "maxw.png"
winsome.defaults.layout_fullscreen = winsome.defaults.layouts_dir .. "fullscreenw.png"
winsome.defaults.layout_tilebottom = winsome.defaults.layouts_dir .. "tilebottomw.png"
winsome.defaults.layout_tileleft = winsome.defaults.layouts_dir .. "tileleftw.png"
winsome.defaults.layout_tile = winsome.defaults.layouts_dir .. "tilew.png"
winsome.defaults.layout_tiletop = winsome.defaults.layouts_dir .. "tiletopw.png"

winsome.defaults.awesome_icon = winsome.shared_dir .. "icons/awesome16.png"
