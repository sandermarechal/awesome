-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- Dynamic tagging
require("shifty")
-- Widgets
require("wicked")
require("vicious")

-- Freedesktop menu
require("freedesktop.utils")
require("freedesktop.menu")
-- Load Debian menu entries
require("debian.menu")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.max,
}
-- }}}

-- {{{ Dynamic tags with Shifty

-- tag settings
shifty.config.tags = {
    ["www"]  = { position = 1, exclusive = true, layout = awful.layout.suit.max },
    ["term"] = { position = 2, exclusive = true, layout = awful.layout.suit.tile.bottom },
    ["dev"] =  { position = 3, exclusive = true, layout = awful.layout.suit.max },
    ["mail"]  = { position = 4, exclusive = true, layout = awful.layout.suit.max },
    ["office"] =  { layout = awful.layout.suit.max, exclusize = true },
    ["gimp"] = { exclusive = true, mwfact = 0.18 },
    ["files"] = { exclusive = true },
    ["im"] = { exclusive = true, layout = awful.layout.suit.fair },
}

-- client settings
-- order here matters, early rules will be applied first
shifty.config.apps = {
        { match = { "Navigator","Vimperator","Gran Paradiso","Firefox","Iceweasel" }, tag = "www" },
        { match = { "Icedove", "Thunderbird" }, tag = "mail" },
        { match = { "xterm", "urxvt", "gnome%-terminal" }, tag = "term", honorsizehints = false },
        { match = { "gvim" } , tag = "dev", honorsizehints = false },
        { match = { "Gimp" } , tag = "gimp" },
        { match = { "gimp%-image%-window" }, slave = true },
        { match = { "OpenOffice" }, tag = "office", honorsizehints = false },
        { match = { "Pidgin", "SFLphone" }, tag = "im" },
        { match = { "Nautilus", "File-roller" }, tag = "files" },
        { match = { "" }, buttons = {
                             button({ }, 1, function (c) client.focus = c; c:raise() end),
                             button({ modkey }, 1, function (c) awful.mouse.client.move() end),
                             button({ modkey }, 3, awful.mouse.client.resize ), }, },
}

-- tag defaults
shifty.config.default_name = "other"
shifty.config.defaults = {
  layout = awful.layout.suit.tile,
  floatBars = true,
}

shifty.init()
-- }}}

--{{{ functions / clientinfo
function client_info()
   local v = ""

   -- object
   local c = client.focus
   v = v .. tostring(c)

   -- geometry
   local cc = c:geometry()
   local signx = (cc.x > 0 and "+") or ""
   local signy = (cc.y > 0 and "+") or ""
   v = v .. " @ " .. cc.width .. 'x' .. cc.height .. signx .. cc.x .. signy .. cc.y .. "\n\n"

   local inf = {
      "name", "icon_name", "type", "class", "role", "instance", "pid",
      "icon_name", "skip_taskbar", "id", "group_id", "leader_id", "machine",
      "screen", "hide", "minimize", "size_hints_honor", "titlebar", "urgent",
      "focus", "opacity", "ontop", "above", "below", "fullscreen", "transient_for"
   }

   for i = 1, #inf do
      v = v .. string.format("%2s: %-16s = %s\n", i, inf[i], tostring(c[inf[i]]))
   end
   naughty.notify{ text = v:sub(1,#v-1), timeout = 0, margin = 10 }
end
--}}}

--{{{ functions / taginfo
function tag_info()
   local t = awful.tag.selected()
   local v = ""

   v = v .. "<span font_desc=\"Verdana Bold 20\">" .. t.name .. "</span>\n"
   v = v .. tostring(t) .. "\n\n"
   v = v .. "clients: " .. #t:clients() .. "\n\n"

   local i = 1
   for op, val in pairs(awful.tag.getdata(t)) do
      if op == "layout" then val = awful.layout.getname(val) end
      if op == "keys" then val = '#' .. #val end
      v = v .. string.format("%2s: %-12s = %s\n", i, op, tostring(val))
      i = i + 1
   end

   naughty.notify{ text = v:sub(1,#v-1), timeout = 0, margin = 10, height = 60 }
end
--}}}

-- {{{ Custom numbering of shift tags. Copy/paste from awful/taglist.lua

--- Return labels for a taglist widget with all tag from screen.
-- It returns the tag name and set a special
-- foreground and background color for selected tags.
-- @param t The tag.
-- @param args The arguments table.
-- bg_focus The background color for selected tag.
-- fg_focus The foreground color for selected tag.
-- bg_urgent The background color for urgent tags.
-- fg_urgent The foreground color for urgent tags.
-- squares_sel Optional: a user provided image for selected squares.
-- squares_unsel Optional: a user provided image for unselected squares.
-- squares_resize Optional: true or false to resize squares.
-- @return A string to print, a background color, a background image and a
-- background resize value.
function taglabels(t, args)
    if not args then args = {} end
    local theme = beautiful.get()
    local fg_focus = args.fg_focus or theme.taglist_fg_focus or theme.fg_focus
    local bg_focus = args.bg_focus or theme.taglist_bg_focus or theme.bg_focus
    local fg_urgent = args.fg_urgent or theme.taglist_fg_urgent or theme.fg_urgent
    local bg_urgent = args.bg_urgent or theme.taglist_bg_urgent or theme.bg_urgent
    local taglist_squares_sel = args.squares_sel or theme.taglist_squares_sel
    local taglist_squares_unsel = args.squares_unsel or theme.taglist_squares_unsel
    local taglist_squares_resize = theme.taglist_squares_resize or args.squares_resize or "true"
    local font = args.font or theme.taglist_font or theme.font or ""
    local text = "<span font_desc='"..font.."'>"
    local sel = client.focus
    local bg_color = nil
    local fg_color = nil
    local bg_image
    local icon
    local bg_resize = false
    local is_selected = false
    if t.selected then
        bg_color = bg_focus
        fg_color = fg_focus
    end
    if sel then
        if taglist_squares_sel then
            -- Check that the selected clients is tagged with 't'.
            local seltags = sel:tags()
            for _, v in ipairs(seltags) do
                if v == t then
                    bg_image = image(taglist_squares_sel)
                    bg_resize = taglist_squares_resize == "true"
                    is_selected = true
                    break
                end
            end
        end
    end
    if not is_selected then
        local cls = t:clients()
        if #cls > 0 and taglist_squares_unsel then
            bg_image = image(taglist_squares_unsel)
            bg_resize = taglist_squares_resize == "true"
        end
        for k, c in pairs(cls) do
            if c.urgent then
                if bg_urgent then bg_color = bg_urgent end
                if fg_urgent then fg_color = fg_urgent end
                break
            end
        end
    end
    if not awful.tag.getproperty(t, "icon_only") then
        local scr = t.screen or 1
        local number = ""
        for i, stag in ipairs(screen[scr]:tags() or {}) do
            if stag == t then
            number = i
            end
        end
        if fg_color then
            text = text .. "<span color='"..awful.util.color_strip_alpha(fg_color).."'>"
            text = " " .. number .. ". " .. text.. (awful.util.escape(t.name) or "") .." </span>"
        else
            text = text .. " " .. number .. ". " .. (awful.util.escape(t.name) or "") .. " "
        end
    end
    text = text .. "</span>"
    if awful.tag.geticon(t) and type(awful.tag.geticon(t)) == "image" then
        icon = awful.tag.geticon(t)
    elseif awful.tag.geticon(t) then
        icon = image(awful.tag.geticon(t))
    end

    return text, bg_color, bg_image, icon
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

menu_items = freedesktop.menu.new()
table.insert(menu_items, 1, { "Awesome", myawesomemenu })
table.insert(menu_items, { "Lock screen", "gnome-screensaver-command -l" })
table.insert(menu_items, { "Logout", "gnome-session-quit --logout" })
table.insert(menu_items, { "Shutdown", "gnome-session-quit --power-off" })
table.insert(menu_items[9][2], { "Home", "nautilus /home/sander" })
table.insert(menu_items[11][2], { "New login", "gdmflexiserver" })

mymainmenu = awful.menu.new({ items = menu_items, width = 200 })
mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
require('calendar2')
mytextclock = awful.widget.textclock({ align = "right" })
calendar2.addCalendarToWidget(mytextclock)

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a CPU usage monitor
cpuwidget = widget({ type = "textbox" })
vicious.register(cpuwidget, vicious.widgets.cpu, ' <span color="white">CPU:</span> $1%')

-- Create a memory usage widget
memwidget = widget({ type = "textbox" })
vicious.register(memwidget, vicious.widgets.mem, ' <span color="white">Mem:</span> $1%', 13)

-- Create a Taskwarrior widget
require('taskwarrior')
mytaskwarrior = taskwarrior.create_widget(1)

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    -- mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)
    mytaglist[s] = awful.widget.taglist(s, taglabels, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mytextclock,
        mytaskwarrior,
        memwidget,
        cpuwidget,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
shifty.taglist = mytaglist

-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Taslwarrior
    awful.key({ modkey },            "=",     taskwarrior.toggle_tasklist),
    -- Info
    awful.key({ modkey,         }, "i", client_info),
    awful.key({ modkey, "Shift" }, "i", tag_info)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",
        function (c)
            awful.client.movetoscreen(c)		
	        shifty.match(c, true, true)
	        c:raise()
        end),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = 9 --math.min(9, shifty.config.maxtags);
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                      local t = screen[mouse.screen or 1]:tags() or {}
                      if t[i] then
                        awful.tag.viewonly(t[i])
                      end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local t = screen[mouse.screen or 1]:tags() or {}
                      if t[i] then
                        awful.tag.viewtoggle(t[i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local t = screen[mouse.screen or 1]:tags() or {}
                          if t[i] then
                              awful.client.movetotag(t[i])
                              awful.tag.viewonly(t[i])
                          end
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                        local t = screen[mouse.screen or 1]:tags() or {}
                        if t[i] then
                          awful.client.toggletag(t[i])
                        end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize)
)

-- Set keys
root.keys(globalkeys)
shifty.config.globalkeys = globalkeys
shifty.config.clientkeys = clientkeys
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    -- { rule = { class = "MPlayer" },
    --   properties = { floating = true } },
    -- { rule = { class = "pinentry" },
    --   properties = { floating = true } },
    -- { rule = { class = "gimp" },
    --   properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
