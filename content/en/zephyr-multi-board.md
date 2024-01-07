+++
title = "Zepyhr: multi-board setup"
author = ["Holger Schurig"]
date = 2024-01-03
tags = ["zephyr", "make", "west", "OpenOCD"]
categories = ["embedded"]
draft = false
+++

This blog post shows how to setup a Zephyr project that you can use for several boards. <br/>

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Why multiple boards in one project?](#why-multiple-boards-in-one-project)
- [(Ab)use of Makefiles](#ab--use-of-makefiles)
- [This blog post is based on ...](#this-blog-post-is-based-on-dot-dot-dot)
- [Board related](#board-related)
    - [Get list of defined board](#get-list-of-defined-board)
    - [Configure and compile for one of the boards](#configure-and-compile-for-one-of-the-boards)
    - [How this is implemented](#how-this-is-implemented)
    - [Configure and compile for simulated hardware](#configure-and-compile-for-simulated-hardware)
    - [Define a local board](#define-a-local-board)
    - [Compiling some sources only for some boards](#compiling-some-sources-only-for-some-boards)
    - [Configuration](#configuration)
- [Get help from make](#get-help-from-make)

</div>
<!--endtoc-->


## Why multiple boards in one project? {#why-multiple-boards-in-one-project}

-   You start with a development board (such as STM Nucleo or Disco) while you <br/>
    wait for the actual hardware prototype. <br/>
-   You want to run hardware-independent unit tests, either on your desktop or on <br/>
    a CI/CD server like Jenkins. <br/>
-   You have to develop for many similar devices that only have slight <br/>
    differences, and you don't want to have many almost-identical source trees. <br/>


## (Ab)use of Makefiles {#ab--use-of-makefiles}

The following is orchestrated mostly by a Makefile. <br/>

Even when Zephyr itself uses CMake and Ninja, Makefiles are a nicer way to <br/>
bundle lots of shell snippets into one Makefile. You can view this Makefile also <br/>
as a collection of knowledge, or as a way to have things replicable. <br/>


## This blog post is based on ... {#this-blog-post-is-based-on-dot-dot-dot}

This post depends and improves on [ Zepyhr: reproducible project setup ]({{< relref "zephyr-reproducible-project-setup" >}}) and uses it's [Makefile.zephyr_init](https://github.com/holgerschurig/zephyr-multi-board/blob/main/Makefile.zephyr_init). <br/>


## Board related {#board-related}


### Get list of defined board {#get-list-of-defined-board}

If we just enter "`make`" to compile our sources, we instead see a list of of boards. <br/>

If we have one set of source files but several target boards, we need a way to <br/>
configure for a specific board. So if there is no "`build/`" directory, we are <br/>
asked to first configure for a specific board: <br/>

```text
:~/src/multi-board-zephyr$ make

-----------------------------------------------------------------------------

You must first select with with board you want to work:

native                configure for native (used for unit-tests)
nucleo                compile for STM32 Nucleo
local                 configure for locally defined board

-----------------------------------------------------------------------------
```


### Configure and compile for one of the boards {#configure-and-compile-for-one-of-the-boards}

We select one of the boards, e.g. the provided STM32 Nucleo one: <br/>

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--86e8d1 }
~/src/multi-board-zephyr$ make nucleo
west build \
	--pristine \
	-b nucleo_f303re \
	-o "build.ninja" \
	-- \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
	-DOVERLAY_CONFIG="nucleo_f303re.conf"
-- west build: generating a build system
Loading Zephyr default modules (Zephyr base).
-- Application: /home/holger/src/multi-board-zephyr
# ... many more lines ...
```

There are some special things here at work: <br/>

-   In line [3](#org-coderef--86e8d1-3), we order "`west`" to use a pristine environment whenever <br/>
    the configuration changes. So you can do "`make local`" and then "`make
        nucleo`" and the "`build/`" directory will completely switch. There's no need <br/>
    for you to manually remove it with "`rm -rf build`". <br/>
    to. <br/>
-   In line [BROKEN LINK: nucleo/f303re], we actually select the wanted board. This one is <br/>
    provided by Zephyr itself, and you can find it in <br/>
    <https://github.com/zephyrproject-rtos/zephyr/tree/main/boards/arm/nucleo/f303re>. <br/>
-   Line [5](#org-coderef--86e8d1-5) tells Zephyr's CMake to use Ninja, which compiles as if we would <br/>
    ask CMake to generate makefiles. <br/>
-   The two dashes in line [6](#org-coderef--86e8d1-6) tell "`west`" to pass over all the future <br/>
    command-line options as-is to CMake. <br/>
-   Line [7](#org-coderef--86e8d1-7) tells CMake to generate a compilation database. Use this with an <br/>
    LSP daemon like clangd or other tools that depend on it. Many editors like <br/>
    Emacs, Visual Studio, etc., offer special services if LSP is present. See more on <br/>
    LSP in the post [ Zepyhr: fixing LSP issues ]({{< relref "zephyr-fixing-lsp-issues" >}}) <br/>
-   Line [8](#org-coderef--86e8d1-8) tells the build system to configure itself according to the <br/>
    specified configuration file. They are in a Linux-style KConfig / ".config" <br/>
    syntax. Note that only board-specific configurations should be placed there. <br/>
    Anything that should be used project-wide has a better place in "prj.conf". <br/>

If the configuration step succeed, this will also automatically compile your code. <br/>

For subsequent compilations, you just enter "`make`" alone. Another "`make
nucleo`" would also re-configure the "`build/`" directory. That would take more <br/>
time. <br/>


### How this is implemented {#how-this-is-implemented}

The differentiation between "`make`" doing just a re-compile or asking you to <br/>
select a board is done like this: <br/>

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--1c9136 }
all::
ifeq ("$(wildcard build/build.ninja)","")           (ref:build.ninja)
	@$(call show_boards)
else
	ninja -C build
endif
```

-   in line [[(build.ninja))] it checks if the build environment inside the <br/>
    "`build/`" directory has been created. If not, it calls the Make function <br/>
    "show_boards". More on this function in a moment. <br/>
-   but if it exists, we just call in line [5](#org-coderef--1c9136-5) "`ninja`" with our build <br/>
    directory as working dir <br/>

The make function is simple enought: basically only some decoration around "`make help_boards`": <br/>

```text
define show_boards
	@echo ""
	@echo "-----------------------------------------------------------------------------"
	@echo ""
	@echo "You must first select with with board you want to work:"
	@$(MAKE) --no-print-directory help_boards
	@echo ""
	@echo "-----------------------------------------------------------------------------"
	@echo ""
endef
```

The reason I made this a function is so that it is easy to call from several <br/>
places. In this Makefile, not only "`make all`" calls it eventually, but also <br/>
maybe "`make menuconfig`" or "`make xconfig`". <br/>

Finally we have a multitude of "help_boards:" targets like this: <br/>

```text
help help_boards::
	@echo "nucleo                configure and compile for STM32 Nucleo"
```


### Configure and compile for simulated hardware {#configure-and-compile-for-simulated-hardware}

Zephyr includes a board called [native_sim](https://docs.zephyrproject.org/latest/boards/posix/native_sim/doc/index.html). Basically when you select this <br/>
"board", your sources are compiled for your development compiter (in my case: <br/>
Linux). So they aren't compiled for ARM or RISV-V, but for x86. The native <br/>
simulator even allows you to similar some hardware, e.g. an AT24 EEPROM. <br/>

However, what is most useful is that you can define unit-tests and run these <br/>
unit-tests than on your develpment compiter --- or on a CI/CD server, like <br/>
Jenkins. <br/>

Here is how you configure Zephyr for this: <br/>

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--50af3b }
.PHONY:: native
native: .west/config
	west build \
		--pristine \
		-b native_sim \
		-o "build.ninja" \
		-- \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		-DOVERLAY_CONFIG="native_sim.conf"
	west build
```

As before, any native-sim-related configuration should be put into <br/>
`"native_sim.conf`", (line [9](#org-coderef--50af3b-9)). <br/>

Now, when we configure and compile, we now get a binary that we can run under <br/>
Linux (or WSL, if you're on Windows): <br/>

```text
~/src/multi-board-zephyr$ make native
west build \
	--pristine \
	-b native_sim \
	-o "build.ninja" \
	-- \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
	-DOVERLAY_CONFIG="native_sim.conf"
-- west build: making build dir /home/holger/src/multi-board-zephyr/build pristine
-- west build: generating a build system
Loading Zephyr default modules (Zephyr base).
-- Application: /home/holger/src/multi-board-zephyr

# ... many lines omitted ...

[93/93] cd /home/holger/src/multi-board-zephyr/bui...ger/src/multi-board-zephyr/build/zephyr/zephyr.ex
```

It's even named "`*.exe`" :-) <br/>

```text
$ file build/zephyr/zephyr.exe
build/zephyr/zephyr.exe: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, BuildID[sha1]=d4b863c9b8d6e9e2265fdef874ec0b9df70efdc9, for GNU/Linux 3.2.0, with debug_info, not stripped
```

And you can call it normally: <br/>

```text
~/src/multi-board-zephyr$ build/zephyr/zephyr.exe
Running TESTSUITE tests
===================================================================
START - demo_test
 PASS - demo_test in 0.000 seconds
===================================================================
TESTSUITE tests succeeded

------ TESTSUITE SUMMARY START ------

SUITE PASS - 100.00% [tests]: pass = 1, fail = 0, skip = 0, total = 1 duration = 0.000 seconds
 - PASS - [tests.demo_test] duration = 0.000 seconds

------ TESTSUITE SUMMARY END ------

===================================================================
PROJECT EXECUTION SUCCESSFUL
```

I will create another blog soon on how to integrate this into Jenkings: by <br/>
converting the output into the TAP format. <br/>


### Define a local board {#define-a-local-board}

So far, we used boards already defined by the Zephyr source code. But perhaps <br/>
you want to use Zephyr on one of your own boards, where you don't plan to <br/>
publish it upstream? That's entirely possible, and the board called "local" in <br/>
this project is exactly that: a board defined for Zephyr but out-of-tree. The <br/>
Makefile snippet for it sounds familiar ... <br/>

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--6f7b48 }
.PHONY:: local
local: .west/config
	west build \
		--pristine \
		-b local \
		-o "build.ninja" \
		-- \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		-DOVERLAY_CONFIG="boards/arm/local/local_defconfig" \
		-DBOARD_ROOT=.
	west build
```

... but there are some differences: <br/>

-   Line [9](#org-coderef--6f7b48-9) gives the full path to the default configuration of the <br/>
    board. <br/>
-   Line [10](#org-coderef--6f7b48-10) specifies our project (not Zephyr) as the board root, so <br/>
    Zephyr won't look into "=zephyr/boards/" but instead into "=boards/" when <br/>
    looking for boards. <br/>

Now we need to have such a "`boards/arm/local/`" directory and populate it with some files: <br/>

| File                | Purpose                                                                                          |
|---------------------|--------------------------------------------------------------------------------------------------|
| Kconfig.board       | this is where you introduce board-specific Kconfig options                                       |
| Kconfig.defconfig   | without setting CONFIG_BOARD to the name of your board, Zephyr wouldn't find the following files |
| board.cmake         | can contain CMake definitions, usually used for OpenOCD or JLink settings                        |
| local.dts           | the Device Tree for your board                                                                   |
| local_defconfig     | the default configuaration for your board, only put things there that isn't in "`prj.conf`"      |
| support/openocd.cfg | if you use OpenOCD, this contains configuration for it                                           |


### Compiling some sources only for some boards {#compiling-some-sources-only-for-some-boards}

This can easily be done via "`CMakeLists.txt`": <br/>

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--a1ada1 }
target_sources(app PRIVATE
  main.c)

target_sources_ifdef(CONFIG_BOARD_LOCAL app PRIVATE
  board_local.c)

target_sources_ifdef(CONFIG_BOARD_NATIVE_SIM app PRIVATE
  board_native.c)
```

-   Any sources that must compile for every board are specified like in line <br/>
    [BROKEN LINK: src/main]. Note that the hanging indent is there as a hint that you can <br/>
    specify multiple source files in one "`target\/source`" declaration. <br/>
-   According to line [BROKEN LINK: src\\/local], the file "`board\/local.c`" will only be <br/>
    compiled if your current board is the board named "local". <br/>
-   And you guessed it; line [BROKEN LINK: src\\/native] ensures that this source file is only <br/>
    considered when compiling for the "native\\/sim" board. Here, I'd put the <br/>
    device-independent unit tests, for example. <br/>

You can use the CONFIG\_ ... variables also direcly in your C sources: <br/>

```text
#ifdef CONFIG_BOARD_LOCAL
   LOG_INF("Running on local")
endif
```


### Configuration {#configuration}

You also learned about the various "`*.conf`" files like <br/>

-   board-specific [native_sim.conf](https://github.com/holgerschurig/zephyr-multi-board/blob/main/native_sim.conf) <br/>
-   board-specific [nucleo_f303re.conf](https://github.com/holgerschurig/zephyr-multi-board/blob/main/nucleo_f303re.conf) <br/>
-   board-specific ones like [boards/arm/local/Kconfig.board](https://github.com/holgerschurig/zephyr-multi-board/blob/main/boards/arm/local/Kconfig.board), <br/>
    [boards/arm/local/Kconfig_defconfig](https://github.com/holgerschurig/zephyr-multi-board/blob/main/boards/arm/local/Kconfig_defconfig) and [boards/arm/local/local_defconfig](https://github.com/holgerschurig/zephyr-multi-board/blob/main/boards/arm/local/local_defconfig) <br/>
-   the project-wide [prj.conf](https://github.com/holgerschurig/zephyr-multi-board/blob/main/prj.conf) file <br/>

But how to find out which "`CONFIG_*`" settings you can use? <br/>

Use either <br/>

-   "`make menuconfig`" or <br/>
-   "`make xconfig`" <br/>

When you make changes and save, you can then just run "`make`" to compile your <br/>
board with these settings. However, to make these changes permanent (and <br/>
reproducible), you need to update one of the configuration files listed above. <br/>


## Get help from make {#get-help-from-make}

I already showed "`make help\/boards`". The same method (multiple pseudo <br/>
makefile targets emitting helpful text) is available to get an idea of what the <br/>
Makefile can do for you: <br/>

```text
~/src/multi-board-zephyr$ make help
init                  do all of these steps:
   debs               only install debian packages
   venv               create and check Python3 virtual environment
   west               install and configure the 'west' tool
   zephyr             clone Zephyr
   modules            install Zeyphr modules (e.g. ST and STM32 HAL, CMSIS ...)
     module_stm32     update only STM32 HAL
     module_st        update only ST HAL
     module_cmsis     update only CMSIS

all                   compile for current board
menuconfig            run menuconfig for current board
xconfig               run xconfig for current board

native                configure and compile for native (used for unit-tests)
nucleo                configure and compile for STM32 Nucleo
local                 configure and compile for locally defined board
```

