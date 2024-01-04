+++
date = "2022-12-13T16:08:00+01:00"
title = "Sway: Application startup via run-or-raise"
tags = [ "sway", "wayland", "dotfiles" ]
categories = [ "Linux" ]
keywords = [ "Sway", "exec", "run-or-raise" ]
+++

In my [Sway configuration](https://github.com/holgerschurig/dotfiles/blob/master/sway/.config/sway/config) I have two lines that start an application in a specific way:

```
bindsym Mod4+e exec ~/.config/sway/run-or-raise Emacs emacs
bindsym Mod4+w exec ~/.config/sway/run-or-raise Firefox firefox
```

What does this do?

First, the "exec" clause calls a python script, [run-or-raise](https://github.com/holgerschurig/dotfiles/blob/master/sway/.config/sway/run-or-raise).

This python scripts wants two arguments. The first one is a container name. It
uses `swaymsg -t get_tree` to get all outputs, work spaces and containers. And
then it looks for any container (that is: application, Wayland client) that
matches the name. This match is actually done case insensitive.

Now we can have 3 outcomes:

* It finds _no_ matching container. In that case, it just starts one with the
  2nd command line argument for the binary / script. And since some applications
  (e.g. Firefox) can take a bit time to start, a short startup notification will
  be displayed.
- It finds _exactly one_ matching container. This container will then get the
  focus using `swaymsg [con_id=...] focus`.
- It finds _several_ matching containers. Then again the logic is like this:
  - none of them has the focus: select the first one to get the focus
  - one of them already has focus: focus the next one, possibly wrapping around
    to the start of the list.

And now, with that I can use `Logo+e` to switch to my Emacs windows, wherever I
am. Normally, Emacs is already started, thanks to my [default Sway layout
setup](../sway-default-layout/).

And `Logo+w` starts a web browser (here Firefox). If already running, it will be
focused. If several separate windows are open, one after the other will be
selected.

I could use tabs as well, but some web applications slow down if they are in an
unselected tab. So I tear out these tabs and put them in separate windows. And I
can quickly select them that way.

This is a (tiny) part of my [Sway configuration](https://github.com/holgerschurig/dotfiles/blob/master/sway/.config/sway/).
