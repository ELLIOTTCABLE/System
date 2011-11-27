winsome = {}

winsome.dir = awful.util.getdir("config") .. "/winsome/"
winsome.icons_dir = winsome.dir .. "icons/"
winsome.awesome_dir = "/usr/share/awesome/"
winsome.default_dir = winsome.awesome_dir .. "themes/default/"

winsome.theme = function(name)
  local theme = {}
  theme.name = name

  -- We assume theme will be installed as ~/.config/awesome/theme/theme_name
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

winsome.defaults.border_width  = "0"
winsome.defaults.border_normal = "#444444"
winsome.defaults.border_focus  = "#000000"
winsome.defaults.border_marked = "#005500"

winsome.defaults.menu_height   = "16"
winsome.defaults.menu_width    = "128"

-- Most of these are from the "Silk" set. See the README for licensing information.
winsome.defaults.taglist_squares_sel   = winsome.icons_dir .. "taglist_bullet_black.png"
winsome.defaults.taglist_squares_unsel = winsome.icons_dir .. "taglist_bullet_white.png"

winsome.defaults.tasklist_floating_icon = winsome.icons_dir .. "floating.png"

winsome.defaults.menu_submenu_icon = winsome.icons_dir .. "expand_submenu.png"

winsome.defaults.titlebar_close_button_normal = winsome.icons_dir .. "close.png"
winsome.defaults.titlebar_close_button_focus  = winsome.defaults.titlebar_close_button_normal

winsome.defaults.titlebar_ontop_button_normal_active   = winsome.icons_dir .. "ontop.png"
winsome.defaults.titlebar_ontop_button_normal_inactive = winsome.icons_dir .. "not_ontop.png"
winsome.defaults.titlebar_ontop_button_focus_active    = winsome.defaults.titlebar_ontop_button_normal_active
winsome.defaults.titlebar_ontop_button_focus_inactive  = winsome.defaults.titlebar_ontop_button_normal_inactive

winsome.defaults.titlebar_sticky_button_normal_active   = winsome.icons_dir .. "sticky.png"
winsome.defaults.titlebar_sticky_button_normal_inactive = winsome.icons_dir .. "not_sticky.png"
winsome.defaults.titlebar_sticky_button_focus_active    = winsome.defaults.titlebar_sticky_button_normal_active
winsome.defaults.titlebar_sticky_button_focus_inactive  = winsome.defaults.titlebar_sticky_button_normal_inactive

winsome.defaults.titlebar_maximized_button_normal_active   = winsome.icons_dir .. "maximized.png"
winsome.defaults.titlebar_maximized_button_normal_inactive = winsome.icons_dir .. "not_maximized.png"
winsome.defaults.titlebar_maximized_button_focus_active    = winsome.defaults.titlebar_maximized_button_normal_active
winsome.defaults.titlebar_maximized_button_focus_inactive  = winsome.defaults.titlebar_maximized_button_normal_inactive

winsome.defaults.titlebar_floating_button_normal_active   = winsome.icons_dir .. "floating.png"
winsome.defaults.titlebar_floating_button_normal_inactive = winsome.icons_dir .. "not_floating.png"
winsome.defaults.titlebar_floating_button_focus_active    = winsome.defaults.titlebar_floating_button_normal_active
winsome.defaults.titlebar_floating_button_focus_inactive  = winsome.defaults.titlebar_floating_button_normal_inactive

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

winsome.defaults.awesome_icon = winsome.awesome_dir .. "icons/awesome16.png"
