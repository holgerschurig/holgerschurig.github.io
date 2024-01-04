+++
title = "Zepyhr: reproducible project setup"
author = ["Holger Schurig"]
date = 2024-01-02
tags = ["zephyr", "make", "west", "OpenOCD"]
categories = ["embedded"]
draft = false
+++

This blog post shows you how to **reproducibly** setup a Zephyr project. It also gives
you a few Makefile tricks and best practices.

While you can do this by hand, e.g. by following the [Getting Started Guide](https://docs.zephyrproject.org/latest/develop/getting_started/index.html), a
reproducible &amp; automatic setup still has benefits. For once, any change you do
is automatically documented in GIT. And also it's much easier to move the
project onto CI/CD servers or into Docker containers.

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [(Ab)use of Makefiles](#ab--use-of-makefiles)
- [Basic project setup](#basic-project-setup)
    - [Make sure you have all dependencies installed](#make-sure-you-have-all-dependencies-installed)
    - [Setting up a python virtual environment](#setting-up-a-python-virtual-environment)
    - [Install the "`west`" tool](#install-the-west-tool)
    - [Install Zephyr](#install-zephyr)
    - [Install needed Zephyr modules, e.g. HALs from the µC vendor](#install-needed-zephyr-modules-e-dot-g-dot-hals-from-the-µc-vendor)
- [Getting help](#getting-help)
- [All of the above](#all-of-the-above)
- [Using this makefile in your project](#using-this-makefile-in-your-project)

</div>
<!--endtoc-->


## (Ab)use of Makefiles {#ab--use-of-makefiles}

All of the following is orchestrated mostly by a Makefile.

Even when Zephyr itself uses CMake and Ninja, Makefiles are a nicer way to
bundle lots of shell snippets into one place. You can view this Makefile also
as a collection of knowledge, or as a way to have things replicatable.

The full Makefile is accessible as
<https://github.com/holgerschurig/zephyr-multi-board/blob/main/Makefile.zephyr_init>


## Basic project setup {#basic-project-setup}


### Make sure you have all dependencies installed {#make-sure-you-have-all-dependencies-installed}

Execution: either "`make init`" or, as a single step, "`make debs`".

How?

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--1ebb54 }
UID := $(shell id -u)

debs .west/stamp.debs:
ifeq ($(UID),0)
	apt install -y --no-install-recommends \
		build-essential \
		ccache \
		cmake \
		device-tree-compiler \
		dfu-util \
		doxygen \
		file \
		g++-multilib \
		gcc \
		gcc-arm-none-eabi \
		gcc-multilib \
		gdb-multiarch \
		git \
		gperf \
		graphviz \
		libmagic1 \
		libnewlib-arm-none-eabi \
		libsdl2-dev \
		make \
		ninja-build \
		openocd \
		plantuml \
		python3-cbor \
		python3-click \
		python3-cryptography \
		python3-dev \
		python3-intelhex \
		python3-pip \
		python3-setuptools \
		python3-tk \
		python3-venv \
		python3-wheel \
		quilt \
		wget \
		xz-utils \
		zip
else
	sudo $(MAKE) --no-print-directory debs
	mkdir -p .west
	touch .west/stamp.debs
endif
```

Here we use a trick: the Makefile detects in line [1](#org-coderef--1ebb54-1) the user ID of the current user. In line
[4](#org-coderef--1ebb54-4) we when check if the Makefile is running as user or root. If it is running as root, we
can use "`apt`" in line [5](#org-coderef--1ebb54-5) to install all the needed dependencies.

However, if we're a normal user, we use "`sudo`" at line [43](#org-coderef--1ebb54-43) to become root
and run the Makefile target "debs" again. The "`--no-print-directory`" command line argument
just removes visual clutter.

Finally, as a normal user, we create a directory if it doesn't yet exist ("`-p")
and put a stamp file into it. "=make init`" checks this stamp, if the stamp
exists, it won't rerun this part. However, "`make debs`" doesn't check the
stamp, it always runs "`apt`". Use this if for some reason you want to install
additional debian packages in an already setup project.


### Setting up a python virtual environment {#setting-up-a-python-virtual-environment}

Zephyr needs a tool called "`west`" which is written in Python and get's installed
via "`pip3`", together with several python modules. In order to have these modules
not interfere with those installed by Debian (or Ubuntu), we need to create a virtual
environent.

Execution: either "`make init`" or, as a single step, "`make debs`".

How?

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--1275dc }
PWD := $(shell pwd)

.PHONY:: venv
init venv:: .west/stamp.debs
ifeq ("$(wildcard .venv/bin/activate)","")
	python3 -m venv $(PWD)/.venv
endif
ifeq ("$(VIRTUAL_ENV)", "")
	@echo ""
	@echo "... ideally by sourcing all environments: source .env"
	@echo ""
	@exit 1
endif

help::
	@echo "   venv               create and check Python3 virtual environment"
```

In line [5](#org-coderef--1275dc-5) we check if the environment already exists (we could use Make's dependency
checking, but it will not just look at the mere existence, but also on the timestamp, which here
is undersirable).

If it doesn't exists, we use the Python "`venv`" module in line [6](#org-coderef--1275dc-6) to simply create one. Now
we could source "`.venv/bin/activate`" to activate this... but unfortunately, this has to be done
outside of Make. Also, we ask to source "`.env`" instead, so that we can also setup needed
[Zephyr environment variables](https://docs.zephyrproject.org/latest/develop/env_vars.html).

Pro tip: on my development PCs, I have a shell function "`pro`" that changes into a project directory
and sources "`.env`" automatically if it exist. It looks like this:

```text
pro ()
{
    cd ~/src/$1 2> /dev/null || cd ~/d/$1 2> /dev/null || cd /usr/src/$1;
    test -f .env && . .env
}
```

So now I can do "`pro cool-zephyr-project`" and my environment is automatically setup.

(This shell function assumes that you have your projects in your home directory
below the "`d`" (like development) or "`src`" directories. Adjust as needed.)


### Install the "`west`" tool {#install-the-west-tool}

Now that we have a virtual environent, we can install the "`west`" tool.

Execution: either “make init” or, as a single step, “make west”.

How?

```text
.PHONY:: west
init:: .west/config
west .west/config:
	@type west >/dev/null || pip3 install west pyelftools
	mkdir -p .west
	/bin/echo -e "[manifest]\npath = zephyr\nfile = west.yml\n[zephyr]\nbase = zephyr" >.west/config
```

Actually this does 3 steps:

-   install west
-   install pyelftools (needed on Debian Bookworm, as the distro provided ones are too old)
-   configure Zephyr via "`.west/config`"


### Install Zephyr {#install-zephyr}

Now we need the source of Zephyr. On some projects, you want the current development
version of it, on some projects you want pin yourself to a specific version. You also
might have local patches for Zephyr that you don't want to publish upstream and that
you want to apply automatically. This step does all of this!

BTW, because of these additional functions (specific version, patches) we intentionally
don't use "`west init`".

Execution: either “make init” or, as a single step, “make zephyr”.

How?

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--802ce8 }
#ZEPHYR_VERSION=zephyr-v3.5.0-3531-g6564e8b756

.PHONY:: zephyr
init:: zephyr/.git/HEAD
zephyr zephyr/.git/HEAD:
	git clone https://github.com/zephyrproject-rtos/zephyr.git
ifneq ("$(ZEPHYR_VERSION)", "")
	cd zephyr; git checkout -b my $(ZEPHYR_VERSION)
endif
ifneq ("$(wildcard patches-zepyhr/series)","")
	ln -s ../patches-zephyr zephyr/patches
	cd zephyr; quilt push -a
endif
```

The first step is a very normal "`git clone`". If you don't care about Zephyr's commit
history (e.g. you don't want to run things like "`git log`" or "`git blame`" you can also
add "--depth 1". That reduces the size of the cloned "`zephyr/`" directory.

You can uncommend and modify ZEPHYR_VERSION in line [1](#org-coderef--802ce8-1) to your liking.
This will pin Zephyr to the specified version. This is done by creating a branch "`my`"
in line [7](#org-coderef--802ce8-7).

What you in ZEPHYR_VERSION is the output of "`git describe --tags`" while I was
in the "`zephyr/`" directory at the point of time where one of my projects moved
from EVT to DVT phase. But you can also simply use tag names from the Zephyr
project.

In one of my projects, I have patches that will probably never be accepted by upstream
Zephyr. I however also don't want to commit them into the "`zephyr/`" project. Instead
I use the "`quilt`" tool to have a stack of patches. BTW, Debian (and thus Ubuntu) also use
quilt to patch upstream source packages before making "`.deb`" files, see their
[howto](https://wiki.debian.org/UsingQuilt) on it.

The existence of quilt patches is checked in line [10](#org-coderef--802ce8-10) and then just
rolled in in line [12](#org-coderef--802ce8-12).


### Install needed Zephyr modules, e.g. HALs from the µC vendor {#install-needed-zephyr-modules-e-dot-g-dot-hals-from-the-µc-vendor}

Some (actually almost all) of the SOCs that Zephyr supports need HALs (hardware
abstraction layers) provided by the chip vendor. If they don't exist, we cannot
compile at all. So let's install them!

Execution: either “make init” or, as a single step, “make modules”.

How?

```text
.PHONY:: modules

init:: modules/hal/stm32/.git/HEAD
.PHONY:: module_stm32
update modules module_stm32 modules/hal/stm32/.git/HEAD:: .west/config
	mkdir -p modules
	west update hal_stm32
	touch --no-create modules/hal/stm32/.git/HEAD

init:: modules/hal/st/.git/HEAD
.PHONY:: module_st
update modules module_st modules/hal/st/.git/HEAD:: .west/config
	mkdir -p modules
	west update hal_st
	touch --no-create modules/hal/st/.git/HEAD

init:: modules/hal/cmsis/.git/HEAD
.PHONY:: module_cmsis
update modules module_cmsis modules/hal/cmsis/.git/HEAD:: .west/config
	mkdir -p modules
	west update cmsis
	touch --no-create modules/hal/cmsis/.git/HEAD
```

As usual, I made the Makefile so that "`make init`" only pulls in the modules
once. However "`make modules`" will always pull them in, should the vendor have
changed them.

Theoretically one could pin the modules also to specific version, like in the
step above. I however noticed that they are quite stable and this was never
needed. And also I need to have something to assign to you as homework, didn't I
????


## Getting help {#getting-help}

If you look at the actual [Makefile](https://github.com/holgerschurig/zephyr-multi-board/blob/main/Makefile.zephyr_init%20), you'll notice that I ommited a whole lot of lines like

```text
help::
	@echo "   modules            install Zeyphr modules (e.g. ST and STM32 HAL, CMSIS ...)"
```

from above. They aren't strictly necessary, but nice. They allow you to run "`make help`" and
see all the common makefile targets meant for users. Like so:

```text
(.venv) holger@holger:~/src/multi-board-zephyr$ make -f Makefile.zephyr_init help
init                  do all of these steps:
   debs               only install debian packages
   venv               create and check Python3 virtual environment
   west               install and configure the 'west' tool
   zephyr             clone Zephyr
   modules            install Zeyphr modules (e.g. ST and STM32 HAL, CMSIS ...)
     module_stm32     update only STM32 HAL
     module_st        update only ST HAL
     module_cmsis     update only CMSIS
```


## All of the above {#all-of-the-above}

The individual targets like "`make venv`" or "`make debs`" are mostly only for
debugging. Once you know they are working, simply run: "`make init`".


## Using this makefile in your project {#using-this-makefile-in-your-project}

You can simply add your own clauses at the end of this Makefile ... your you can include it from
a main Makefile. This is demonstrated in the Github project <https://github.com/holgerschurig/zephyr-multi-board/>:

Main "`Makefile`"

```text
PWD := $(shell pwd)
UID := $(shell id -u)

.PHONY:: all
all::


# Include common boilerplate Makefile to get Zephyr up on running
include Makefile.zephyr_init

# ... many more lines ...
```

First at the top we set two environment variables that we often use, PWD
(working directory) and UID (user id). You can then later just use them via
"$(PWD)" --- note that Make want's round brances here, not curly braces like
Bash.

Then I set a default target, to be executed if you just run "`make`" without specifying
a target by yourself.

The double colon here needs to be used for all targets that are defined more
than once in a Makefile. As you see, here the target is empty. It's fleshed out
in much more complexity below, but this is beyond this blog post.

Also note the "`.PHONY:: all`" line. It helps Make to understand that "`make`"
or "`make all`" isn't supposed to actually create file called "`all`". This
helps it's dependency resolvement engine, and is good style. My makefile uses
"`.PHONY::`" liberally, for each pseudo-target (shell script snippet) basically.

Finally, we use Make's "`include`" clause to include our boilerplate Makefile.

You could also run the Boilerplate makefile itself, with "`make -f
Makefile.zephyr_init`", e.g. for debugging purposes. But oh ... now PWD and UID
aren't set. So at the top of this makefile I set these variables if they don't exist:

```text
ifeq ($(PWD),"")
PWD := $(shell pwd)
endif
ifeq ($(UID),"")
UID := $(shell id -u)
endif
```
