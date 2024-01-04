+++
date = "2017-01-22"
title = "AwesomeWM: Alternative bindings setup"
tags = [ "awesome", "dotfiles" ]
categories = [ "Linux" ]
keywords = [ "awesome", "awesomewm", "key bindings" ]

+++

The default `rc.lua` from the Awesome window manager uses a lot of
`globalkeys = awful.util.table.join(...)` code.

I disliked this because ...

- in Lua, the last field of a table cannot have a comma. So often when
  I moved an entry around, I ended up with a pointless syntax error 
  because of a missing or trailing comma
- adding elements by joining seems somewhat complex
- adding logic, e.g. only adding a keybinding under specific
  circumstances is suddenly more difficult
  
So let's change this ...

<!--more-->

Note: the following works with AwesomeWM v4.0. I used v4.0-105-gbfb35349.


## Define binding functions

I define a function where I can add one binding at a time:

``` lua
local tinsert = table.insert

globalkeys = {}    
function globalkey(mod, key, func, desc)
   local key = awful.key(mod, key, func, desc)
   for k,v in pairs(key) do
      tinsert(globalkeys, v)
   end
end

clientkeys = {}
function clientkey(mod, key, func, desc)
   local key = awful.key(mod, key, func, desc)
   for k,v in pairs(key) do
      tinsert(clientkeys, v)
   end
end
```

## Example usage

``` lua
-- TAGS
globalkey({ modkey }, "Escape",
   awful.tag.history.restore,
   {description = "Previous tag", group = "Tags"})
globalkey({ modkey }, "Right",
   awful.tag.viewnext,
   {description = "Tag forward", group = "Tags"})
globalkey({ modkey }, "Left",
   awful.tag.viewprev,
   {description = "Tag backword", group = "Tags"})
```

I think this looks generally more pleasing. See
my
[bindings.lua](https://bitbucket.org/holgerschurig/dotfiles/src/HEAD/awesome-4/.config/awesome/bindings.lua?at=master&fileviewer=file-view-default) file
a longer example.
