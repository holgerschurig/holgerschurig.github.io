+++
title = "Zepyhr: reproducible project setup"
author = ["Holger Schurig"]
date = 2024-01-02
tags = ["zephyr", "make", "west", "OpenOCD"]
categories = ["embedded"]
draft = false
+++

This blog post demonstrates how to set up a Zephyr project in a **reproducible** <br/>
manner. Additionally, it provides some Makefile tricks and best practices for <br/>
using this powerful tool effectively. <br/>

While you can set up a Zephyr project manually, following the [Getting Started <br/>
Guide](https://docs.zephyrproject.org/latest/develop/getting/started/index.html), a reproducible and automatic approach has several advantages. Firstly, <br/>
any changes made to the project will be automatically documented in GIT. <br/>
Furthermore, it is easier to move the project onto CI/CD servers or into Docker <br/>
containers. <br/>

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

The entire setup is primarily managed by a Makefile. Despite the fact that <br/>
Zephyr utilizes CMake and Ninja, Makefiles offer a more convenient way to <br/>
consolidate numerous shell commands into a single location. You can consider <br/>
this Makefile as a repository of knowledge or as a mechanism for ensuring <br/>
replicability. <br/>

The full Makefile is accessible as <br/>
<https://github.com/holgerschurig/zephyr-multi-board/blob/main/Makefile.zephyr_init> <br/>


## Basic project setup {#basic-project-setup}


### Make sure you have all dependencies installed {#make-sure-you-have-all-dependencies-installed}

Execution: either "`make init`" or, as a single step, "`make debs`". <br/>

How? <br/>

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

In this section, we employ a trick using the Makefile to detect the user ID of <br/>
the current user in line [1](#org-coderef--1ebb54-1). Line [4](#org-coderef--1ebb54-4) is used to verify if the <br/>
Makefile is running as a user or root. If it's running as root, we can utilize <br/>
"`apt`" in line [5](#org-coderef--1ebb54-5) to install all necessary dependencies. <br/>

If we're non-root, we use "`sudo`" in line [43](#org-coderef--1ebb54-43) to become root and execute the <br/>
"debs" Makefile target again. The "`--no-print-directory`" command-line argument <br/>
is employed to remove visual clutter from the output. <br/>

Lastly, as a normal user, we create the directory "`.west`" if it doesn't exist <br/>
("`-p`") and place a stamp file inside it. The "`make init`" command checks the <br/>
existence of the stamp, preventing unnecessary re-execution of this part if it <br/>
already exists. In contrast, "`make debs`" does not check for the stamp and <br/>
always runs "`apt`". This can be used if you want to install additional Debian <br/>
packages in an existing project setup. <br/>


### Setting up a python virtual environment {#setting-up-a-python-virtual-environment}

Zephyr requires a tool named "`west`" that is written in Python and is installed <br/>
using "`pip3`". Along with several Python modules. To prevent these modules from <br/>
conflicting with those installed by Debian (or Ubuntu), we need to create a <br/>
virtual environment. <br/>

Execution: either "`make init`" or, as a single step, "`make debs`". <br/>

How? <br/>

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

In line [5](#org-coderef--1275dc-5), we verify if the environment already exists. While Make's <br/>
dependency checking can be used for this purpose, it would check not only for <br/>
file existence, but also for the timestamp. In this case, this is undesirable. <br/>

If the environment does not exist, we use the Python "`venv`" module in line <br/>
[6](#org-coderef--1275dc-6) to create one. While we could source "`.venv/bin/activate`" to activate <br/>
this within Make, unfortunately, it has to be done outside of Make. Instead, we <br/>
ask to source "`.env`" so that we can also set up the required Zephyr <br/>
environment variables. <br/>

Pro tip: On my development PCs, I have a shell function "`pro`" that <br/>
automatically changes into a project directory and sources "`.env`" if it <br/>
exists. It looks like this: <br/>

```text
pro ()
{
    cd ~/src/$1 2> /dev/null || cd ~/d/$1 2> /dev/null || cd /usr/src/$1;
    test -f .env && . .env
}
```

So now I can do "`pro cool-zephyr-project`" and my environment is automatically <br/>
setup. <br/>

(This shell function assumes that you have your projects in your home directory <br/>
below the "`d`" (like development) or "`src`" directories. Adjust as needed.) <br/>


### Install the "`west`" tool {#install-the-west-tool}

Now that we have a virtual environent, we can install the "`west`" tool. <br/>

Execution: either “make init” or, as a single step, “make west”. <br/>

How? <br/>

```text
.PHONY:: west
init:: .west/config
west .west/config:
	@type west >/dev/null || pip3 install west pyelftools
	mkdir -p .west
	/bin/echo -e "[manifest]\npath = zephyr\nfile = west.yml\n[zephyr]\nbase = zephyr" >.west/config
```

Actually this does 3 steps: <br/>

-   install west <br/>
-   install pyelftools (needed on Debian Bookworm, as the distro provided ones are too old) <br/>
-   configure Zephyr via "`.west/config`" <br/>


### Install Zephyr {#install-zephyr}

Now we require the source of Zephyr. On some projects, you may want to use the <br/>
current development version, while on others, you may wish to pin yourself to a <br/>
specific version. Additionally, you might have local patches for Zephyr that you <br/>
don't want to publish upstream and that you want to apply automatically. This <br/>
step accomplishes all of this! <br/>

Execution: either “make init” or, as a single step, “make zephyr”. <br/>

How? <br/>

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

The first step is a typical "`git clone`". If you don't care about Zephyr's <br/>
commit history (e.g., you don't want to run things like "`git log`" or "`git
blame`"), you can also add "`--depth 1`". This reduces the size of the cloned <br/>
"`zephyr/`" directory. <br/>

**Specific version**: you can uncommend and modify ZEPHYR_VERSION in line [1](#org-coderef--802ce8-1) to your liking. <br/>
This will pin Zephyr to the specified version. This is done by creating a branch "`my`" <br/>
in line [7](#org-coderef--802ce8-7). <br/>

BTW, the value of ZEPHYR_VERSION is the output of "`git describe --tags`". <br/>

Background: when should you start to lock Zephyr? This depends on your <br/>
circumstances. When a project is still in EVT phase, I tend to follow Zephyr <br/>
closely, e.g. use development version so it. "`ZEPYHR_VERSION`" would be <br/>
uncommented then. But then the projects enters DVT phase, or even MP phase, I'll <br/>
certainly lock Zephyr to a well-known version. <br/>

**Local patches**: in one of my projects, I have patches that will probably never <br/>
be accepted by upstream Zephyr. I could put them directly into Zephyr, in my own <br/>
branch ... but I prefer to have them in my own GIT project. So I use the <br/>
"`quilt`" tool to manage a stack of patches. <br/>

The existence of quilt patches is checked in line [10](#org-coderef--802ce8-10) and, if they <br/>
exist, line [12](#org-coderef--802ce8-12) rolls them in. <br/>

**Final note**: It's worth mentioning that due to version pinning and local <br/>
patches, we intentionally don't use "`west init`" in this step. <br/>


### Install needed Zephyr modules, e.g. HALs from the µC vendor {#install-needed-zephyr-modules-e-dot-g-dot-hals-from-the-µc-vendor}

Some (actually almost all) of the SOCs that Zephyr supports need HALs (hardware <br/>
abstraction layers) provided by the chip vendor. If they don't exist, we cannot <br/>
compile at all. So let's install them! <br/>

Execution: either “make init” or, as a single step, “make modules”. <br/>

How? <br/>

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

As usual, I made the Makefile so that "`make init`" only pulls in the modules <br/>
once. However "`make modules`" will always pull them in, should the vendor have <br/>
changed them. <br/>

Theoretically one could pin the modules also to specific version, like in the <br/>
step above. I however noticed that they are quite stable and this was never <br/>
needed. And also I need to have something to assign to you as homework, didn't I <br/>
???? <br/>


## Getting help {#getting-help}

If you look at the actual [Makefile](https://github.com/holgerschurig/zephyr-multi-board/blob/main/Makefile.zephyr_init%20), you'll notice that I ommited a whole lot of lines like <br/>

```text
help::
	@echo "   modules            install Zeyphr modules (e.g. ST and STM32 HAL, CMSIS ...)"
```

from above. They aren't strictly necessary, but nice. They allow you to run "`make help`" and <br/>
see all the common makefile targets meant for users. Like so: <br/>

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

The individual targets like "`make venv`" or "`make debs`" are mostly only for <br/>
debugging. Once you know they are working, simply run: "`make init`". <br/>


## Using this makefile in your project {#using-this-makefile-in-your-project}

You can simply add your own clauses at the end of this Makefile ... your you can include it from <br/>
a main Makefile. This is demonstrated in the Github project <https://github.com/holgerschurig/zephyr-multi-board/>: <br/>

Main "`Makefile`" <br/>

```text
PWD := $(shell pwd)
UID := $(shell id -u)

.PHONY:: all
all::


# Include common boilerplate Makefile to get Zephyr up on running
include Makefile.zephyr_init

# ... many more lines ...
```

First at the top we set two environment variables that we often use, PWD <br/>
(working directory) and UID (user id). You can then later just use them via <br/>
"$(PWD)" --- note that Make want's round brances here, not curly braces like <br/>
Bash. <br/>

Then I set a default target, to be executed if you just run "`make`" without specifying <br/>
a target by yourself. <br/>

The double colon here needs to be used for all targets that are defined more <br/>
than once in a Makefile. As you see, here the target is empty. It's fleshed out <br/>
in much more complexity below, but this is beyond this blog post. <br/>

Also note the "`.PHONY:: all`" line. It helps Make to understand that "`make`" <br/>
or "`make all`" isn't supposed to actually create file called "`all`". This <br/>
helps it's dependency resolvement engine, and is good style. My makefile uses <br/>
"`.PHONY::`" liberally, for each pseudo-target (shell script snippet) basically. <br/>

Finally, we use Make's "`include`" clause to include our boilerplate Makefile. <br/>

You could also run the Boilerplate makefile itself, with "`make -f
Makefile.zephyr_init`", e.g. for debugging purposes. But oh ... now PWD and UID <br/>
aren't set. So at the top of this makefile I set these variables if they don't exist: <br/>

```text
ifeq ($(PWD),"")
PWD := $(shell pwd)
endif
ifeq ($(UID),"")
UID := $(shell id -u)
endif
```

