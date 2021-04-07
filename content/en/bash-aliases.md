+++
date = "2016-03-25T17:39:29+01:00"
title = "bash aliases"
tags = [ "bash", "dotfiles" ]
topics = [ "Linux" ]

+++

Here are the bash aliases that I like and install almost everywhere.

<!--more-->

Listing directories
-------------------
First, here are some aliases that set defaults for listing files.

Switch  | Meaning
--------|------
-l      | long list
-A      | show all files, even hidden ones
-F      | decorate file types, e.g. append an "/" after directory names

``` bash
alias l="ls -lF"
alias ll="ls -lAF"
alias ls="ls -F"
```

Navigating directories
----------------------


``` bash
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"
```

Command substitution
--------------------
And finally I have some small aliases that modify the standard
behavior of commands. In case I would need the original behavior, I'd
call it with ``/bin/rm``:

``` bash
alias md="mkdir"
alias diff="diff -u"
alias rm="rm -i"
```
