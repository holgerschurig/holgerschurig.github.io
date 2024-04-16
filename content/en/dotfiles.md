+++
title = "Dotfiles (and setup)"
author = ["Holger Schurig"]
date = 2024-04-16
tags = ["linux"]
categories = ["config"]
draft = false
+++

Normally dotfile repositories contain:

-   **configuration**

This dotfiles project also allow you to:

-   **group** the configurations
-   install only a **select configs**
-   can **disable** installation (e.g. battery support not on Desktop)
-   **install Debian packages**
-   **run** shell scripts

It is therefore a step into the "reproducible build" direction.

<!--more-->

You find the project at <https://github.com/holgerschurig/dotfiles>

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Nomenclature](#nomenclature)
- [Stow directories](#stow-directories)
- [Apply scripts](#apply-scripts)
    - [apply_check()](#apply-check)
    - [apply_run()](#apply-run)
- [Data directories](#data-directories)
- [Usable variables and functions](#usable-variables-and-functions)
    - [$APPLY_UNIT](#apply-unit)
    - [$APPLY_DIR](#apply-dir)
    - [$APPLY_FORCE](#apply-force)
    - [$APPLY_DEBUG](#apply-debug)
    - [debug()](#debug)
    - [info()](#info)
    - [warning()](#warning)
    - [error()](#error)
    - [install_deb()](#install-deb)
    - [apply_stow()](#apply-stow)

</div>
<!--endtoc-->


## Nomenclature {#nomenclature}

apply unit
: installs or executes shell scripts: config files, Debian
    packages, other apply units. Example: "`wayland-wofi`", "`x11-openbox`". You
    start installation of them with the "`./apply`" script: "./apply
    wayland-wofi=". Can have one (or all) of the this: apply script, stow
    directory, data directory.


apply script
: can disable the apply unit based on shell script logic. Use
    this to install some things only on some computers. But more importantly, it
    can execute arbitrary shell commands. Use this if installing a config file
    would be cumbersome, e.g. to add a user to a specific group. We don't want
    to put "`group`" and "`gshadow`" for that into this project and overwrite
    the system ones --- wouldn't work if some Debian package also create groups!


"`.stow`" directory
: contain configuration files that are installed using
    [GNU stow](https://www.gnu.org/software/stow/).


"`.data`" directory
: contain other data files that you want to handle
    without [GNU stow](https://www.gnu.org/software/stow/). Usually because because applications like "`sudo`" will barf
    on config files that are symlinks.


## Stow directories {#stow-directories}

The "`*.stow`" directories contain file system trees. With the help of [GNU stow](https://www.gnu.org/software/stow/) they
are copied to either "`/`" or "`$HOME`". But ... actually GNU stow doesn't copy them.
That would create redundancy. Instead it symlinks them. Let's give you an example:

The directory [wayland-ironbar](https://github.com/holgerschurig/dotfiles/tree/master/wayland-ironbar) contains this tree:

```text
$ find wayland-ironbar.stow/
wayland-ironbar.stow/
wayland-ironbar.stow/.config
wayland-ironbar.stow/.config/ironbar
wayland-ironbar.stow/.config/ironbar/config.yaml
wayland-ironbar.stow/.config/ironbar/style.css
```

When you run

```text
$ ./apply wayland-ironbar
```

The following files will be created:

```text
$ ls -lR ~/.config/ironbar
/home/holger/.config/ironbar:
total 8
lrwxrwxrwx 1 holger holger 63 Apr 16 11:28 config.yaml -> ../../dotfiles/wayland-ironbar.stow/.config/ironbar/config.yaml
lrwxrwxrwx 1 holger holger 61 Apr 16 11:28 style.css -> ../../dotfiles/wayland-ironbar.stow/.config/ironbar/style.css
```

So Ironbar can access it's config.yaml file just as normal. But in reality they continue to exist in the "`dotfiles/wayland-ironbar/`" directory.

This is nice, because if you now change "`~/.config/ironbar/config.yaml`" you
see in the dotfiles project (via git) that and what you changed. And then you
can commit this, never ever forgetting to commit and push your changes.


## Apply scripts {#apply-scripts}

For each apply unit, you can have an optional shell script. These scripts are
sourced from the "`apply`" script. So they aren't executable by themselves. They
can however access any function / variable defined in "`apply`".

The idea here is that the scripts can define two functions:


### apply_check() {#apply-check}

This function checks if the apply unit should be executed at all.

For example, to make an apply unit only run in the Podman container with the
hostname "apply", we can do this:

```text
apply_check()
{
        # "apply" is the hostname of the container
        test "$HOSTNAME" = "apply"
}
```

If "`apply_check()`" returns false, the whole apply unit will not be applied.


### apply_run() {#apply-run}

The other function you can define is "`apply_run()". Everything in it is executed if
"=apply_check()`" is missong or returns true.

Usually you use that to install Debian packages. Or to add a user to some group.
Or to install files that you cannot stow (e.g. because a program would ignore
symlinks, see [Data directories](#org-target--data)).

Here is an example:

```text
apply_run()
{
    apt-get install -y openbox
}
```

I have some apply units that are used to group others. For example, the "`root`"
apply unit applies lots of others:

```text
apply_run()
{
    apply root-apt
    apply root-bash
    apply root-inputrc
    apply root-joe
    apply root-tools
    apply root-aptitude
    apply root-sudo
    apply root-user
}
```

So running "`./apply root`" will apply all of these apply units to the system.


## Data directories<span class="org-target" id="org-target--data"></span> {#data-directories}

A few programs check their config files. E.g. "`sudo`" will ignore a "`sudoers`"
file if it doesn't have a suitable permission. Or if it is a symlink. That not
really compatible with [GNU stow](https://www.gnu.org/software/stow/), so we need a workaround.

```text
apply_run()
{
   # So we use "install" for this :-)
   # note that if a .data file exists, then ./apply will automatically switch into it
   install -m644 -o0 -g0 sudoers /etc/sudoers
}
```

This "`sudoers`" file is then taken from "`root-sudo.data/sudoers`".

Note that the source parameter of the "`install`" command didn't specify a
directory. This works because "`./apply`" cd'ed into this directory before
running the apply script.


## Usable variables and functions {#usable-variables-and-functions}

"`apply`" defines several variables and functions useful for apply scripts:


### $APPLY_UNIT {#apply-unit}

If you run "`./apply root-sudo`" then "`$APPLY_UNIT`" will be set to "`root-sudo`".


### $APPLY_DIR {#apply-dir}

This contains the directory of where the "`apply`" script resides, e.g. "`/home/schurig/dotfiles`".


### $APPLY_FORCE {#apply-force}

Set to "1" if you call "`apply`" with the "`-f`" command line switch. Otherwise "0". Used if an apply
unit is called another time (basically making it ignore stamp files in the "`.stamps`" directory).


### $APPLY_DEBUG {#apply-debug}

Set to "1" if you call "`apply`" with the "`-d`" command line switch. Otherwise "0".


### debug() {#debug}

Usage is like echo:

```text
debug "This is a test, APPLY_DIR is $APPLY_DIR"
```

However, the text is only emitted if "`apply`" is called with the "`-d`" command line switch.


### info() {#info}

Usage is like echo, too.

However, the text is shown with a green "Info: " prefix to make it stand out.


### warning() {#warning}

Usage is like echo, too.

However, the text is shown with a blue "Warning: " prefix to make it stand out.


### error() {#error}

Usage is like echo, too.

However, the text is shown with a red "Error: " prefix to make it stand out.

Also, "`apply`" is automatically aborted with an error level of 1.


### install_deb() {#install-deb}

Installs Debian packages. It is however a bit faster than normal "`apt-get`" in finding
out if the package is already installed, since it checks files in "`/var/lib/dpkg/info/`" first. "`apt-get`"
first loads the complete package cache.

"`install_deb()`" also uses "`eatmydata`" to make installation MUCH faster. This
basically turns off all the "=sync(2)" calls.

And finally, should you run "`./apply`" as user, then it will use "`sudo`" to
become root for the actual installation.

Example:

```text
apply_run()
{
    install_deb \
        xserver-common \
        xserver-xorg-core \
        xserver-xorg-video-intel \
        xserver-xorg-input-evdev \
        x11-utils \
        x11-xserver-utils \
        xinput \
        xinit
}
```


### apply_stow()<span class="org-target" id="org-target--applystow"></span> {#apply-stow}

This calls either "`stow -t /`" or "`stow -t $HOME`", depending if we execute a
root or user apply unit.
