+++
date = "2022-12-13T18:28:00+01:00"
title = "Sway: tweaks and (un)usual keybindings"
tags = [ "sway", "wayland", "dotfiles" ]
topics = [ "Linux" ]
keywords = [ "Sway", "layout" ]
mastodon = "109507768476455476"
+++

When I started to configure Sway, I found a lot of configurations online, but
mostly were exactly the same. I too based my configuration on the [given
example](https://github.com/swaywm/sway/blob/master/config.in), but disgressed
quite a bit.

<!--more-->

No $mod
-------
I can't see ever that I would use some other key for Sway functions than the `Logo` key of
my keyboard. So why have a variable and tenthousend (tm) times `$mod` in the config when
I can directly write `Mod4` everywhere?


No hjkl and unneeded introduction
---------------------------------
All the Sway configurations used something like

```
set $left h
set $down j
set $up k
set $right l
...
    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right
```

That way 4 perfectly usable character keys were used for functions that are
equally suited for cursor key. I removed that, and reused some of the
Logo+`<character>` combinations.


No weird indentation
--------------------
Did you notice that above the `set` is not indented, but the `bindsym` is? I
have no clue why. The indentation doesn't transport any hierarchy. Be done with
it!


Using run-or-raise
------------------
Sway doesn't implement this, but I wrote a Python program for that. See my
[extra post](../sway-run-or-raise/) for details.


Using types for input
---------------------
The example config still uses named entities for input configuration. Here is
line from the example:

```
input "2:14:SynPS/2_Synaptics_TouchPad" {
    ...
}
```

But ... if you want to configure your keyboard layout (e.g. to German) and you don't
know the exact name?  You need to know first that you can run `swaymsg -t get_inputs`. Then
select the proper one and use it.

But it can be done easier, by using types:

```
input type:touchpad {
    ...
}
```

See `man 5 sway-input` for the available types. As the time of this writing,
it's touchpad, pointer, keyboard, touch, tablet_tool, tablet_pad and switch.

And with that, my keyboard setup looks this:

```
input type:keyboard {
    xkb_model   "pc101"
    xkb_layout  "de(nodeadkeys)"
    repeat_delay 300
    repeat_rate  20
}
```

and will stay this even when my current "LITE-ON Technology USB NetVista Full
Width Keyboard." breaks.


Remove mouse cursor when typing
-------------------------------
That would need an extra program on X11, but with Sway it's built in:

```
input type:mouse {
    dwt true
    ...
}
```


Background color
----------------
A lot of people load background images. I use however specifically a tiling window manager to maximize
my screen estate. I even auto-start [emacs and alacritty](../sway-default-layout/) automatically when
starting Sway. So I can do with a simply black screen:

```
output * {
    background #000000 solid_color
    ...
}
```

No title bars except when needed
--------------------------------
Normally, I know exactly my clients. So I can do without the title:

```
default_border pixel 1
```

But .. sometimes I need then. So I can toggle the title an and off. Sadly, Logo+`t` is already
used for the tabbed layout, so I used Logo+`b`:

```
bindsym Mod4+b border normal
bindsym Mod4+Shift+b border pixel 1
```

But, if I use Sway's "mark client" feature to swap to windows, I want the title bar pop up. This is
because Sway writes `[Mark]` into the marked client's title. Therefore, Logo+`m` first marks the client
and then turns its border (and therefore title) on:

```
bindsym Mod4+m mark --add --toggle Mark, border normal
bindsym Mod4+Shift+m swap container with mark Mark
```

There is currently no automation to un-do this visible title automatically, I do
that manually. Maybe I can automate this with "criteria" trickery.


A waybar that isn't one
-----------------------
Almost all monitors these days are very wide, but not so tall. However, almost
all bars are horizontal oriented. I know that I can configure waybar also
vertically. I even tried that, but I didn't like the look of it.

And so I made a bar that isn't one: it's a overlay. Normally, I just see the
date/time in the lower left window. Should I go into a specific mode (currently
I only have the "resize" mode), then I'll see that on the right side.

```
bar {
    position bottom
    status_command while date +'%d.%m.%y %H:%M:%S'; do sleep 1; done
    mode overlay
    workspace_buttons no
    font pango:Sans 11
    colors {
        statusline #ffffff
        background #ffffff10
        inactive_workspace #32323200 #32323200 #5c5c5c
    }
}
```


Run programs via menu
---------------------
For some reasons, the example configurations had this on Logo+`d`. Why `d`?  Remnant from `dmenu`?
I put it on Logo+`r`. `r` like `run`.

```
bindsym Mod4+r exec wofi --show=run --lines=25 --prompt=""
```


Application startup keys
------------------------
```
bindsym Mod4+Return exec alacritty
bindsym Mod4+e exec ~/.config/sway/run-or-raise Emacs emacs
bindsym Mod4+w exec ~/.config/sway/run-or-raise Firefox firefox
```

The Logo+`Return` way to start a terminal I kept. It's something of a common thing, even
AwesomeWM had this by default.

But I added two start/focus keys for Emacs and Firefox. I wrote details of this in an [extra post](../sway-run-or-raise/).



Dangerous / unusual things via Shift
------------------------------------
I already introduced above some Logo+Shift+... keybinding. And I omitted the boring ones,
like moving a client to different workspace.

But mostly the Mod4+Shift+... are for "dangerous" or "unusual" things:

```
bindsym Mod4+Shift+d layout default
bindsym Mod4+Shift+q exec swaymsg exit    # kill Sway
bindsym Mod4+Shift+k kill                 # kill client
bindsym Mod4+Shift+r reload
bindsym Mod4+Shift+s layout stacking
bindsym Mod4+Shift+t layout tabbed
```

Three characters (`d`, `s` and `t`) are to switch the layouts. Which I seldom
do, and that therefore might confuse me.

Killing a client is certainly dangerous, so I have it on Logo+Shift+`k`.

Even more dangerous is killing whole of Sway, it's on Logo+Shift+`q`. Maybe I
should put in on Ctrl+Alt+Backspace, for some old X11 feeling?

Reloading without running `sway --validate` first can also be dangerous. Okay,
only annoying. AwesomeWM was much worse here. Still, I bound that to Logo+Shift+`q`.


Caveats
-------
Probably you need to publish your blog now twice:

* publish blog
* fetch it's URL, post Mastodon toot with it
* determine the Mastodon ID
* add the Mastodon ID to your frontmatter
* publish blog again

Another possible problem is: if you edit your Mastodon toot, then the ID of it will change.

But if you can life with that, you have a free, you've found a privacy
respecting method of letting people comment on your posts.


Outro
-----
All of the above is visible in my [~/.config/sway/config](https://github.com/holgerschurig/dotfiles/blob/master/sway/.config/sway/config)
file.
