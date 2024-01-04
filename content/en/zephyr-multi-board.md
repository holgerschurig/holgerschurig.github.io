+++
title = "Zepyhr: multi-board setup"
author = ["Holger Schurig"]
date = 2024-01-03
tags = ["zephyr", "make", "west", "OpenOCD"]
categories = ["embedded"]
draft = false
+++

This blog post shows how to setup a Zephyr project that you can use for several boards.

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

-   you start with a development board (like STM Nucleo or Disco) while you wait
    for the actual hardware prototype
-   you want to run (hardware-independent) [unit-tests](https://docs.zephyrproject.org/latest/develop/test/ztest.html), either on your desktop or
    on a CI/CD server like Jenkings
-   you have to develop for many similar devices that only have slight differences
    and don't want to have many almost-identical source trees


## (Ab)use of Makefiles {#ab--use-of-makefiles}

Most of the following is orchestrated mostly by a Makefile.

Even when Zephyr itself uses CMake and Ninja, Makefiles are a nicer way to
bundle lots of shell snippets into one Makefile. You can view this Makefile also
as a collection of knowledge, or as a way to have things replicatable.


## This blog post is based on ... {#this-blog-post-is-based-on-dot-dot-dot}

This blog post depends on Macro test [ Zepyhr: reproducible project setup ]({{< relref "zephyr-reproducible-project-setup" >}}) and uses it's [Makefile.zephyr_init](https://github.com/holgerschurig/zephyr-multi-board/blob/main/Makefile.zephyr_init).


## Board related {#board-related}


### Get list of defined board {#get-list-of-defined-board}

Now that you created the Zephyr development environment using [ Zepyhr: reproducible project setup ]({{< relref "zephyr-reproducible-project-setup" >}}), added some
sources and a "`CMakeLists.txt`" file you enter "`make`" to compile your
project.

But instead of compiling your source, you see a list of available boards:

```text
:~/src/multi-board-zephyr$ make

-----------------------------------------------------------------------------

You must first select with with board you want to work:

native                configure for native (used for unit-tests)
nucleo                compile for STM32 Nucleo
local                 configure for locally defined board

-----------------------------------------------------------------------------
```

The reason is that we don't yet know for which board you actually want to
compile your sources.

Basically, if no "`build/`" directory exists, you get this help text with all
configured boards inside the Makefile.


### Configure and compile for one of the boards {#configure-and-compile-for-one-of-the-boards}

So instead, select board, and enter "`make nucleo`" instead. And now Zephyr
configures itself and compiles:

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--b0b636 }
~/src/multi-board-zephyr$ make nucleo
west build \
	--pristine \
	-b nucleo_f303re \
	-o "build.ninja" \
	-- \
	-Wno-dev \
	-Wno-deprecated \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
	-DOVERLAY_CONFIG="nucleo_f303re.conf"
-- west build: generating a build system
Loading Zephyr default modules (Zephyr base).
-- Application: /home/holger/src/multi-board-zephyr
# ... many more lines ...
```

There are some special things here at work:

-   in line [3](#org-coderef--b0b636-3) we order "`west`" to use a pristine environment whenever
    the configuration changes. So you can do "`make local`" and then "`make
        nucleo`" and the "`build/`" directory will completely switch. While you can do
    "`rm -rf build`" you don't need to, due to this "`--pristine`" command line
    switch
-   in line [4](#org-coderef--b0b636-4) we actually select the wanted boards. This one is
    provided by Zephyr itself, you can find it in
    <https://github.com/zephyrproject-rtos/zephyr/tree/main/boards/arm/nucleo_f303re>
-   line [5](#org-coderef--b0b636-5) tells Zephyr's CMake to use Ninja, which is faster compiling
    compared to let CMake generate Makefiles.
-   the two dashes in line [6](#org-coderef--b0b636-6) tells "`west`" to pass over all the future command
    line-options as-is to CMake.
-   line [9](#org-coderef--b0b636-9) tells CMake to generate a compilation database. Use this with an
    LSP daemon like clangd or other tools that depend it. Many editors like Emacs,
    Visual Studio etc offer special services if LSP is present.
-   line [10](#org-coderef--b0b636-10) tell the build system to configure itself according to this
    config files (which has Linux KConfig / "`.config`" syntax. Note that only
    board-specific configuration should be placed there. Anything that should be
    used project-wide has a better place in "`prj.conf`".

If the configuration step succeed, this will also automatically compile your code.

Here are the last few lines of the compilation process:

```text
Memory region         Used Size  Region Size  %age Used
           FLASH:       39782 B       512 KB      7.59%
             RAM:        9792 B        64 KB     14.94%
             CCM:          0 GB        16 KB      0.00%
        IDT_LIST:          0 GB         2 KB      0.00%
Generating files from /home/holger/src/multi-board-zephyr/build/zephyr/zephyr.elf for board: nucleo_f303re
[147/147] cd /home/holger/src/multi-board-zephyr/b...ger/src/multi-board-zephyr/build/zephyr/zephyr.el
(.venv) holger@holger:~/src/multi-board-zephyr$ file build/zephyr/zephyr.bin
build/zephyr/zephyr.bin: ARM Cortex-M firmware, initial SP at 0x20001fc0, reset at 0x08002f30, NMI at 0x08002bec, HardFault at 0x08002f1c, SVCall at 0x08003054, PendSV at 0x08002fec
```


### How this is implemented {#how-this-is-implemented}

The above "`make nucleo`" is implemented by this Makefile part:

```text
.PHONY:: nucleo
nucleo: .west/config
	west build \
		--pristine \
		-b nucleo_f303re \
		-o "build.ninja" \
		-- \
		-Wno-dev \
		-Wno-deprecated \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		-DOVERLAY_CONFIG="nucleo_f303re.conf"
	west build

help help_boards::
	@echo "nucleo                compile for STM32 Nucleo"
```

Note the last two lines: we have a Makefile pseudo-target "`help_boards`" which
can exist several times in the Makefile (because it uses "::" and not ":"). Each of our board
configuration snippets contains such an entry.

Now, if you simply run "`make`", then the pseudo-target "all" will be executed.
And it looks like this:

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--1c9136 }
all::
ifeq ("$(wildcard build/build.ninja)","")           (ref:build.ninja)
	@$(call show_boards)
else
	ninja -C build
endif
```

-   in line [[(build.ninja))] it checks if the build environment inside the
    "`build/`" directory has been created. If not, it calls the Make function
    "show_boards". More on this function in a moment.
-   but if it exists, we just call in line [5](#org-coderef--1c9136-5) "`ninja`" with our build
    directory as working dir

The make function is simple enought: basically only some decoration around "`make help_boards`":

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

The reason I made this a function is so that it is easy to call from several
places. In this Makefile, not only "`make all`" calls it eventually, but also
maybe "`make menuconfig`" or "`make xconfig`".


### Configure and compile for simulated hardware {#configure-and-compile-for-simulated-hardware}

Zephyr includes a "board" called [native_sim](https://docs.zephyrproject.org/latest/boards/posix/native_sim/doc/index.html). Basically your sources are compiled
for this target, but they run on your development computer (e.g. compiled to
x86, not for ARM). The native simulator even allows you to similar some
hardware, e.g. an AT24 EEPROM.

However, what is most useful is that you can define unit-tests and run these unit-tests
than on your develpment compiter --- or on a CI/CD server, like Jenkins.

Here is how you configure Zephyr for this:

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

As before, any native-sim-related configuration should be put into
`"native_sim.conf`", (line [9](#org-coderef--50af3b-9)).

Now, when we configure and compile, we now get a binary that we can run under
Linux (or WSL, if you're on Windows):

```text
$ make native
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

It's even named "`*.exe`" :-)

```text
$ file build/zephyr/zephyr.exe
build/zephyr/zephyr.exe: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, BuildID[sha1]=d4b863c9b8d6e9e2265fdef874ec0b9df70efdc9, for GNU/Linux 3.2.0, with debug_info, not stripped
```

And you can call it normally:

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

I will create another blog soon on how to integrate this into Jenkings: by
converting the output into the TAP format.


### Define a local board {#define-a-local-board}

So far, we used boards already defined by the Zephyr source code. But perhaps
you want to use Zephyr on one of your own boards, where you don't plan to
publish it upstream? That's entirely possible, and the board called "local" of this project is exactly that: a board defined for Zephyr, but out-of-tree.

The Makefile snippet for it sounds familiar ...

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

... but there is some differences:

-   line [9](#org-coderef--6f7b48-9) gives a full path to the default config of the board
-   line [10](#org-coderef--6f7b48-10) specifies OUR project (not Zephyr) as the board root. So
    Zephyr won't look into "`zephyr/boards/...`" but instead into "`boards/...`"
    when looking for boards.

Now we need to have such a "`boards/arm/local/`" directory and populate it with some files:

| File                | Purpose                                                                                          |
|---------------------|--------------------------------------------------------------------------------------------------|
| Kconfig.board       | this is where you introduce board-specific Kconfig options                                       |
| Kconfig.defconfig   | without setting CONFIG_BOARD to the name of your board, Zephyr wouldn't find the following files |
| board.cmake         | can contain CMake definitions, usually used for OpenOCD or JLink settings                        |
| local.dts           | the Device Tree for your board                                                                   |
| local_defconfig     | the default configuaration for your board, only put things there that isn't in "`prj.conf`"      |
| support/openocd.cfg | if you use OpenOCD, this contains configuration for it                                           |


### Compiling some sources only for some boards {#compiling-some-sources-only-for-some-boards}

This can easily be done via "`CMakeLists.txt`":

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--a1ada1 }
target_sources(app PRIVATE
  main.c)

target_sources_ifdef(CONFIG_BOARD_LOCAL app PRIVATE
  board_local.c)

target_sources_ifdef(CONFIG_BOARD_NATIVE_SIM app PRIVATE
  board_native.c)
```

-   any sources that must compile for every board is specified like in line
    [2](#org-coderef--a1ada1-2). Note that the hanging indent is there as a hint that you can
    specify multiple source files in one "`target_source`" declaration.
-   according to line [4](#org-coderef--a1ada1-4) the file "`board_local.c`" will only be compiled
    if your current board is the board named "local".
-   and you guessed it, line [7](#org-coderef--a1ada1-7) makes sure that this source file is only
    considered when compiling for the "native_sim" board. Here I'd put the
    device-independent unit-tests, for example.

You can use the CONFIG\_ ... variables also direcly in the sources:

```text
#ifdef CONFIG_BOARD_LOCAL
   LOG_INF("Running on local")
endif
```


### Configuration {#configuration}

You also learned about the various "`*.conf`" files like

-   board-specific [native_sim.conf](https://github.com/holgerschurig/zephyr-multi-board/blob/main/native_sim.conf)
-   board-specific [nucleo_f303re.conf](https://github.com/holgerschurig/zephyr-multi-board/blob/main/nucleo_f303re.conf)
-   board-specific ones like [boards/arm/local/Kconfig.board](https://github.com/holgerschurig/zephyr-multi-board/blob/main/boards/arm/local/Kconfig.board), [boards/arm/local/Kconfig_defconfig](https://github.com/holgerschurig/zephyr-multi-board/blob/main/boards/arm/local/Kconfig_defconfig) and [boards/arm/local/local_defconfig](https://github.com/holgerschurig/zephyr-multi-board/blob/main/boards/arm/local/local_defconfig)
-   the project-wide [prj.conf](https://github.com/holgerschurig/zephyr-multi-board/blob/main/prj.conf) file

But how to find out which "`CONFIG_*`" settings you can use?

Use either

-   "`make menuconfig`" or
-   "`make xconfig`"

When you make changes there and save, you can then just run "`make`" to compile
your board with these settings. However, to make these changes permanent (and
thus reproducible), you need to update on of the configuration files I listed
above.


## Get help from make {#get-help-from-make}

I already showed "`make help_boards`". The same method (multiple pseudo makefile
targets emitting helpful text) is available to get an idea of what the Makefile can do for you:

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
