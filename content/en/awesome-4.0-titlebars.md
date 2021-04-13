+++
date = "2017-01-22"
title = "AwesomeWM: about title bars and toggling them"
tags = [ "awesome", "dotfiles" ]
topics = [ "Linux" ]
keywords = [ "awesome", "awesomewm", "title bars", "floating" ]

+++

The default `rc.lua` from Awesome 4.0 turns title bars on. Here I show
how you can turn them off, and also how I enable them only for
floating clients.

<!--more-->

Note: the following works with AwesomeWM v4.0. I used v4.0-105-gbfb35349.


## Removing the title bars
Users of awesome 3.5.x are surprised that suddenly all clients have a title bar.

This is because the rules file in the default `rc.lua` contains those lines:

``` lua
-- Add title bars to normal clients and dialogs
{ rule_any = {type = { "normal", "dialog" }
  }, properties = { titlebars_enabled = true }
},
```

So removing the title bars is as easy as changing the `true` to `false`.


## Removing the title bars only for non-floating clients

However, now no title bar will ever created. If you want to show a title bar
for a floating client, you cannot do that: there exists none. So let's change
the `false` back to `true`.

Now title bars will be created in the signal handler for the signal
`request::titlebar`. At the end of the handling function, add this code:

``` lua
    ...
        layout = wibox.layout.align.horizontal
    }
    -- Hide the menubar
    awful.titlebar.hide(c)
end)
```

This hides the newly created title bar. Or, maybe we want to hide the
title bar only sometimes, then use:

``` lua
    ...
        layout = wibox.layout.align.horizontal
    }
    -- Hide the menubar if we are not floating
    local l = awful.layout.get(c.screen)
    if not (l.name == "floating" or c.floating) then
        awful.titlebar.hide(c)
    end
```

And now you can still toggle the title bar, e.g. with this binding:

``` lua
clientkey({ modkey, "Control" }, "t",
   awful.titlebar.toggle,
   {description = "Toggle title bar", group = "Clients"})
```

(See my blog post about [keybindings]({{< relref "en/awesome-4.0-bindings.md" >}}) to learn
about the `clientkey()` function.)


## Turning title bars on when a client is floating

Or you can show/hide the title bar automatically whenever you toggle
the floating attribute if you add this property signal handler:

``` lua
client.connect_signal("property::floating", function (c)
    if c.floating then
        awful.titlebar.show(c)
    else
        awful.titlebar.hide(c)
    end
end)
```
A possible binding might be:

``` lua
clientkey({ modkey, "Control" }, "o",
   function (c) c.floating = not c.floating end,
   {description = "Toggle floating", group = "Clients"})
```

## Turning on the title bars when the layout is floating

But what is when I don't set a single client to floating mode (e.g. via rules,
or via a keybinding), but when I use the floating layout suit?  As often, a signal
handler can help here:

```lua
awful.tag.attached_connect_signal(s, "property::layout", function (t)
    local float = t.layout.name == "floating"
    for _,c in pairs(t:clients()) do
        c.floating = float
    end
end)
```
