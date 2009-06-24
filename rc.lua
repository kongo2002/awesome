require("awful")
require("beautiful")
require("naughty")

-- import custom functions
require("functions")

theme_path = os.getenv("HOME") .. "/.config/awesome/themes/current/theme"

-- Actually load theme
beautiful.init(theme_path)

terminal = "urxvt"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.max,
    awful.layout.suit.floating
}
layout_icons =
{   ["tile"] = "[]=",
    ["tileleft"] = "=[]",
    ["tilebottom"] = "[v]",
    ["tiletop"] = "[^]",
    ["fairv"] = "[|]",
    ["fairh"] = "[-]",
    ["max"] = "[x]",
    ["floating"] = "[~]"
}

-- Table of clients that should be set floating. 
floatapps =
{
    ["Gimp"] = true,
    ["pidgin"] = true,
    ["Skype"] = true
}

-- Applications to be moved to a pre-defined tag by class or instance.
-- Use the screen and tags indices.
apptags =
{
    ["Firefox"] = { screen = 1, tag = 2 },
    ["gvim"] = { screen = 1, tag = 3 },
    ["Gimp"] = { screen = 1, tag = 5 }
}

-- Define if we want to use titlebar on all applications.
use_titlebar = false
-- }}}

-- {{{ Tags

-- layout   : layout to use
-- mwfact   : master width factor
-- nmaster  : number of master windows
-- ncol     : number of columns for slave windows

tag_properties = {
    { name = "main", layout = layouts[1] },
    { name = "www", layout = layouts[1] },
    { name = "dev", layout = layouts[5] },
    { name = "4", layout = layouts[1] },
    { name = "5", layout = layouts[8] },
    { name = "6", layout = layouts[8] }
}

-- Define tags table.
tags = {}

for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = {}

    for i, v in ipairs(tag_properties) do
        tags[s][i] = tag(v.name)
        tags[s][i].screen = s

        awful.tag.setproperty(tags[s][i], "layout", v.layout)
        awful.tag.setproperty(tags[s][i], "mwfact", v.mwfact)
        awful.tag.setproperty(tags[s][i], "nmaster", v.nmaster)
        awful.tag.setproperty(tags[s][i], "ncols", v.ncols)
    end

    tags[s][1].selected = true
end
-- }}}

-- {{{ Wibox

-- Create a laucher widget and a main menu
awesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mainmenu = awful.menu.new({ items = { { "awesome", awesomemenu },
                                        { "open terminal", terminal }
                                      }
                            })

-- Create a systray
mysystray = widget({ type = "systray", align = "right" })

-- Simple spacer for cleaner code
spacer = " "

-- Create a wibox for each screen and add it
mywibox = {}
promptbox = {}
layoutbox = {}
taglist = {}
taglist.buttons = { button({ }, 1, awful.tag.viewonly),
                      button({ modkey }, 1, awful.client.movetotag),
                      button({ }, 3, function (tag) tag.selected = not tag.selected end),
                      button({ modkey }, 3, awful.client.toggletag),
                      button({ }, 4, awful.tag.viewnext),
                      button({ }, 5, awful.tag.viewprev) }
tasklist = {}
tasklist.buttons = { button({ }, 1, function (c)
                                          if not c:isvisible() then
                                              awful.tag.viewonly(c:tags()[1])
                                          end
                                          client.focus = c
                                          c:raise()
                                      end),
                       button({ }, 3, function () if instance then instance:hide() end instance = awful.menu.clients({ width=250 }) end),
                       button({ }, 4, function ()
                                          awful.client.focus.byidx(1)
                                          if client.focus then client.focus:raise() end
                                      end),
                       button({ }, 5, function ()
                                          awful.client.focus.byidx(-1)
                                          if client.focus then client.focus:raise() end
                                      end) }
-- Add date text widget
datebox = widget({ type = "textbox", name = "datebox", align = "right" })

-- Add a mpd text widget
mpdbox = widget({ type = "textbox", name = "mpdbox", align = "right" })

-- Add a memory text widget
membox = widget({ type = "textbox", name = "membox", align = "right" })

-- Add a file system text widget
fsbox = widget({ type = "textbox", name = "fsbox", align = "right" })

-- Add a cpu text widget
cpubox = widget({ type = "textbox", name = "cpubox", align = "right" })

-- Add a network interface text widget
netbox = widget({ type = "textbox", name = "netbox", align = "right" })

-- Add a processes text widget
procbox = widget({ type = "textbox", name = "procbox", align = "right" })

for s = 1, screen.count() do
    -- Create a promptbox for each screen promptbox[s] = widget({ type = "textbox", align = "left" })

    -- Create a textbox widget with layout indicator
    layoutbox[s] = widget({ type = "textbox", name = "layoutbox", align = "left" })
    layoutbox[s]:buttons({
        button({ }, 1, function () awful.layout.inc(layouts, 1) end),
        button({ }, 3, function () awful.layout.inc(layouts, -1) end),
        button({ }, 4, function () awful.layout.inc(layouts, 1) end),
        button({ }, 5, function () awful.layout.inc(layouts, -1) end)
    })

    -- Get according layout icon
    layoutbox[s].text = getlayouticon(s)

    -- Set icon colours 
    layoutbox[s].fg = beautiful.fg_focus
    layoutbox[s].bg = beautiful.bg_normal

    -- Create a taglist widget
    taglist[s] = awful.widget.taglist.new(s, awful.widget.taglist.label.all, taglist.buttons)

    -- Create a tasklist widget
    -- Modification: only display currently focussed task
    tasklist[s] = awful.widget.tasklist.new(
        function(c)
            if c == client.focus and c ~= nil then
                return spacer .. setFg(beautiful.fg_focus, c.name)
            end
        end, tasklist.buttons)

    -- Create the wibox
    mywibox[s] = wibox({ position = "top",
                        fg = beautiful.fg_normal, 
                        bg = beautiful.bg_normal,
                        border_color = beautiful.border_wibox,
                        border_width = beautiful.border_width_wibox
    })

    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = { taglist[s],
                           layoutbox[s],
                           tasklist[s],
                           promptbox[s],
                           cpubox,
                           procbox,
                           membox,
                           fsbox,
                           netbox,
                           mpdbox,
                           datebox,
                           s == 1 and mysystray or nil }
    mywibox[s].screen = s
end
-- }}}

-- {{{ Mouse bindings
root.buttons({
    button({ }, 3, function () mainmenu:toggle() end),
    button({ }, 4, awful.tag.viewnext),
    button({ }, 5, awful.tag.viewprev)
})
-- }}}

-- {{{ Key bindings
globalkeys =
{
    key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    key({ modkey, "Shift"   }, "Escape", awful.tag.history.restore),

    key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),

    -- Layout manipulation
    key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1) end),
    key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1) end),
    key({ modkey, "Control" }, "j", function () awful.screen.focus( 1)       end),
    key({ modkey, "Control" }, "k", function () awful.screen.focus(-1)       end),
    key({ modkey,           }, "u", awful.client.urgent.jumpto),
    key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Custom bindings
    key({ modkey,           }, "f",     function () awful.util.spawn("firefox") end),
    key({ modkey,           }, "t",     function () awful.util.spawn("thunderbird") end),
    key({ modkey,           }, "n",     function () awful.util.spawn("mpc next") end),

    -- Standard program
    key({ modkey, "Shift"   }, "Return", function () awful.util.spawn(terminal) end),
    key({ modkey, "Control" }, "r", awesome.restart),
    key({ modkey, "Shift"   }, "q", awesome.quit),

    key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    key({ modkey }, "F1",
        function ()
            awful.prompt.run({ prompt = " Run: " },
            promptbox[mouse.screen],
            awful.util.spawn, awful.completion.bash,
            awful.util.getdir("cache") .. "/history")
        end),

    key({ modkey }, "F4",
        function ()
            awful.prompt.run({ prompt = " Run Lua code: " },
            promptbox[mouse.screen],
            awful.util.eval, awful.prompt.bash,
            awful.util.getdir("cache") .. "/history_eval")
        end),
}

-- Client awful tagging: this is useful to tag some clients and then do stuff like move to tag on them
clientkeys =
{
    key({ modkey, "Shift"   }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    key({ modkey,           }, "Escape", function (c) c:kill()                         end),
    key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    key({ modkey }, "t", awful.client.togglemarked),
    key({ modkey,}, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),
}

-- Compute the number of tags
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

for i = 1, keynumber do
    table.insert(globalkeys,
        key({ modkey }, i,
            function ()
                local screen = mouse.screen
                if tags[screen][i] then
                    awful.tag.viewonly(tags[screen][i])
                end
            end))
    table.insert(globalkeys,
        key({ modkey, "Control" }, i,
            function ()
                local screen = mouse.screen
                if tags[screen][i] then
                    tags[screen][i].selected = not tags[screen][i].selected
                end
            end))
    table.insert(globalkeys,
        key({ modkey, "Shift" }, i,
            function ()
                if client.focus and tags[client.focus.screen][i] then
                    awful.client.movetotag(tags[client.focus.screen][i])
                end
            end))
    table.insert(globalkeys,
        key({ modkey, "Control", "Shift" }, i,
            function ()
                if client.focus and tags[client.focus.screen][i] then
                    awful.client.toggletag(tags[client.focus.screen][i])
                end
            end))
end


for i = 1, keynumber do
    table.insert(globalkeys, key({ modkey, "Shift" }, "F" .. i,
                 function ()
                     local screen = mouse.screen
                     if tags[screen][i] then
                         for k, c in pairs(awful.client.getmarked()) do
                             awful.client.movetotag(tags[screen][i], c)
                         end
                     end
                 end))
end

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Hooks
-- Hook function to execute when focusing a client.
awful.hooks.focus.register(function (c)
    if not awful.client.ismarked(c) then
        c.border_color = beautiful.border_focus
    end
end)

-- Hook function to execute when unfocusing a client.
awful.hooks.unfocus.register(function (c)
    if not awful.client.ismarked(c) then
        c.border_color = beautiful.border_normal
    end
end)

-- Hook function to execute when marking a client
awful.hooks.marked.register(function (c)
    c.border_color = beautiful.border_marked
end)

-- Hook function to execute when unmarking a client.
awful.hooks.unmarked.register(function (c)
    c.border_color = beautiful.border_focus
end)

-- Hook function to execute when the mouse enters a client.
awful.hooks.mouse_enter.register(function (c)
    -- Sloppy focus, but disabled for magnifier layout
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

-- Hook function to execute when a new client appears.
awful.hooks.manage.register(function (c, startup)
    -- If we are not managing this application at startup,
    -- move it to the screen where the mouse is.
    -- We only do it for filtered windows (i.e. no dock, etc).
    if not startup and awful.client.focus.filter(c) then
        c.screen = mouse.screen
    end

    if use_titlebar then
        -- Add a titlebar
        awful.titlebar.add(c, { modkey = modkey })
    end
    -- Add mouse bindings
    c:buttons({
        button({ }, 1, function (c) client.focus = c; c:raise() end),
        button({ modkey }, 1, awful.mouse.client.move),
        button({ modkey }, 3, awful.mouse.client.resize)
    })
    -- New client may not receive focus
    -- if they're not focusable, so set border anyway.
    c.border_width = beautiful.border_width
    c.border_color = beautiful.border_normal

    -- Check if the application should be floating.
    local cls = c.class
    local inst = c.instance
    if floatapps[cls] then
        awful.client.floating.set(c, floatapps[cls])
    elseif floatapps[inst] then
        awful.client.floating.set(c, floatapps[inst])
    end

    -- Check application->screen/tag mappings.
    local target
    if apptags[cls] then
        target = apptags[cls]
    elseif apptags[inst] then
        target = apptags[inst]
    end
    if target then
        c.screen = target.screen
        awful.client.movetotag(tags[target.screen][target.tag], c)
    end

    -- Do this after tag mapping, so you don't see it on the wrong tag for a split second.
    client.focus = c

    -- Set key bindings
    c:keys(clientkeys)

    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- awful.client.setslave(c)

    -- Honor size hints: if you want to drop the gaps between windows, set this to false.
    -- c.size_hints_honor = false
end)

-- Hook function to execute when arranging the screen.
-- (tag switch, new client, etc)
awful.hooks.arrange.register(function (screen)
    -- change layout notifier (--> functions.lua)
    layoutbox[screen].text = getlayouticon(screen)

    -- Give focus to the latest client in history if no window has focus
    -- or if the current window is a desktop or a dock one.
    if not client.focus then
        local c = awful.client.focus.history.get(screen, 0)
        if c then client.focus = c end
    end
end)

-- Hook called every minute
awful.hooks.timer.register(60, function ()
    fsbox.text = setFg(beautiful.fg_focus, "F: ")..fsInfo("/dev/sda4")
    datebox.text = os.date(" %d.%m.%y %H:%M ")
end)

-- Hook called every 10 seconds
awful.hooks.timer.register(10, function ()
    membox.text = setFg(beautiful.fg_focus, "M: ")..memInfo()
end)

-- Hook called every 2 seconds
awful.hooks.timer.register(2, function ()
    cpubox.text = setFg(beautiful.fg_focus, "C: ")..cpuInfo()
    procbox.text = setFg(beautiful.fg_focus, "P: ")..procInfo()
    netbox.text = setFg(beautiful.fg_focus, "N: ")..netInfo()
    mpdbox.text = setFg(beautiful.fg_focus, "MPD: ")..getMpd()
end)
-- }}}

-- Initial execution of several functions
membox.text = setFg(beautiful.fg_focus, "M: ")..memInfo()
fsbox.text = setFg(beautiful.fg_focus, "F: ")..fsInfo("/dev/sda4")
datebox.text = os.date(" %d.%m.%y %H:%M ")

-- Autostart .xinitrc
awful.util.spawn("~/.xinitrc &")
