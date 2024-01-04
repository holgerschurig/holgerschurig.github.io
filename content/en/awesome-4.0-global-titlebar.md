+++
date = "2017-01-22"
title = "AwesomeWM: using a global title bar"
tags = [ "awesome", "dotfiles" ]
categories = [ "Linux" ]
keywords = [ "awesome", "awesomewm", "title bars" ]

+++

This post shows how you can create a global titlebar. I personally removed the
tasklist and replaced this with the titlebar. The tasklist wasn't good looking anyway
and so far I don't miss the tasklist.

<!--more-->

Note: the following works with AwesomeWM v4.0. I used v4.0-127-g0be3b071.


## Create the global title bar
Creating the title bar is easy enough:

``` lua
local wibox = require("wibox")
local mytitle = wibox.widget {
    markup = "Awesome: press Win-s for help",
    align = "left",
    widget = wibox.widget.textbox
}
```

As you can see, the default text is a help text that guides you towards the new
hotkey widget.

Now we need to put this title onto our screens. Look for this text

```lua
s.mytasklist, -- Middle widget
```

and replace it with

``` lua
{ -- Middle widget
    mytitle,
    layout = wibox.container.margin,
    left = 12,
},
```

The extra margin gives us some leeway towards the tags, or towards a run prompt.


## Connect the title bar to clients

Up to now the title bar just display this help text. That's nice, but that's not what
we want. So we need to add some signal handlers.

- whenever a client get's focus, use it's class and name for the tile
- whenever a client is unfocused, reinstall the help text

``` lua
client.connect_signal("focus", function (c)
    mytitle.markup = c.class .. ": " .. c.name
end)
client.connect_signal("unfocus", function (c)
    mytitle.markup = "Awesome: press Win-s for help"
end)
```

Many clients (e.g. "urxvt" or "emacs") update their title on-the-fly. We can
get notified about this as well:

``` lua
client.connect_signal("property::name", function(c)
    -- ignore property changes from unfocused clients
    if c == client.focus then
        mytitle.markup = c.class .. ": " .. c.name
    end
end)
```
