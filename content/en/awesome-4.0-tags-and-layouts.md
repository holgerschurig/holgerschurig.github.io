+++
date = "2017-01-22"
title = "AwesomeWM: Tags and Layout setup"
tags = [ "awesome", "dotfiles" ]
categories = [ "Linux" ]
keywords = [ "awesome", "awesomewm", "tags", "layouts", "rc.lua" ]

+++

In this post I show a nice method to define tags and associated
layouts, where the tag names change dynamically when the layout
changes.

<!--more-->

Note: the following works with AwesomeWM v4.0. I used v4.0-105-gbfb35349.


## Current situation

When you look at the example `rc.lua` file, you see that tags and layout setup
is spread over several places.

First, you have this long list of available layouts:

``` lua
-- Table of layouts to cover with awful.layout.inc, order matters
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
```

and then, where the screens get setup, you see:

``` lua
-- Each screen has its own tag table.
awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])
```

I disliked several things here:

- the numbers aren't telling me much
- when I change the numbers to roles, e.g. "www", "dev", "music" I
  loose flexibility. Maybe I don't have "music" at the work, but at
  home ...
- as a layout is tightly coupled to a tag, it would probably be better
  to reflect the layout in the tag name.
- initializing all tags with the same layout seems unflexible

So let's work toward a setup that will fit more to my taste.


## Define tags and layouts in one go

I first define a table that contains which tags I want **and** their
default layout:

``` lua
local my_tag_list = {
    awful.layout.suit.fair,
    awful.layout.suit.fair,
    awful.layout.suit.fair,
    awful.layout.suit.floating,
    awful.layout.suit.max,
}
```

With this example, I would end up with 5 tags.


## Automatically set awful.layout.layouts

This is completely optional. If you don't want this, then setup
`awful.layout.layouts` like in the example rc.lua.

Awesome needs `awful.layout.layouts` set. It uses when you
increment/decrement the layout, e.g with the mouse or some keybinding.
Instead of manually setting this up, we can use `my_tag_list` as a
source for it.

``` lua
awful.layout.layouts = {}
for _,v in pairs(my_tag_list) do
    if not awful.util.table.hasitem(awful.layout.layouts, v) then
        table.insert(awful.layout.layouts, v)
    end
end
```

## Attach tags and layouts to the screens

We can now attach our tags and layouts to the screens:

``` lua
-- put this inside the `awful.screen.connect_for_each_screen` function:
for i,l in ipairs(my_tag_list) do
    awful.tag.add(i .. ":" .. shorten_layout_name(l.name),
                  {layout = l,
                   screen = s,
                   selected = i==1})
end
```

An observant reader will have noticed that I used a function
`shorten_layout_name()`. That's just because I want my tag/layout
names to be short, e.g. around 4 characters wide.

``` lua
function shorten_layout_name(name)
    if name == "fullscreen" then name = "full"
    elseif name == "floating" then name = "float"
    elseif name == "fairv" then name = "fair"
    elseif name == "termfair" then name = "term" end
    return name
end
```

## Automatically change the tag names when layout changes

The taglist will now look like

``` text
4:fair 5:fait 6:fair 7:float 8:max
```
	
This will be wrong as soon as I change the layout of a tag. So I need
to react to some signals. Define this function:

``` lua
local function tagbox_update_tagname(t)    
    t.name = t.index .. ":" .. shorten_layout_name(t.layout.name)
end
```

And now just assign this function to two signals:

``` lua
-- put this inside the `awful.screen.connect_for_each_screen` function:
awful.tag.attached_connect_signal(s, "tagged", tagbox_update_tagname)
awful.tag.attached_connect_signal(s, "property::layout", tagbox_update_tagname)
```
