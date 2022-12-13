+++
date = "2022-12-13T15:30:00+01:00"
title = "Sway: default initial layout"
tags = [ "sway", "wayland", "dotfiles" ]
topics = [ "Linux" ]
keywords = [ "Sway", "layout" ]
+++

When I start Sway, I'd like to have Emacs on the left side of workspace 1, and a terminal (here Alacritty)
on the right side, Unfortunately, this `~/.config/sway/config` except won't work:

```
exec emacs
exac alacritty
```

Because alacritty starts much faster than Emacs. So I'd get the terminal on the right side of the screen.
And Emacs on the left. Not good.

Instead, I do this:

```
exec emacs
for_window [class="^Emacs$"] exec sh -c 'pgrep -x alacritty >/dev/null || alacritty'
for_window [app_id="^emacs$"] exec sh -c 'pgrep -x alacritty >/dev/null || alacritty'
```

That is, I start Emacs. And I add two `for_window` rules that fire when an Sway
container with the named criteria is created. The first line is for Emacs
compiled for X11. And the second line would fire if your Emacs is compiled for
PGTK, which you should only do when you run Emacs under Wayland.

The result will look like this:

![img](./sway-default-layout.png)

This is a (tiny) part of my [Sway configuration](https://github.com/holgerschurig/dotfiles/blob/master/sway/.config/sway/config).
