+++
title = "Multi-Board setup for Zephyr"
author = ["Holger Schurig"]
date = 2024-01-02
tags = ["zephyr", "make", "west"]
categories = ["embedded"]
draft = false
+++

## Why? {#why}

Here I document how to compile one Zephyr RTOS source-code base against
different targets. Why can this be helpful?

-   your EE collegues are cool ... but still you need to wait longer than expected
    for the prototype board. In the meantime, you want to start development on
    some development board, like Nucleo or Disco
-   some of your logic can be checked via unit-tests --- and luckily Zephyr has a
    [test framework](https://docs.zephyrproject.org/latest/develop/test/ztest.html) built it. It would however be swell if you CI/CD pipeline could
    automatically run these tests, e.g. with the help of [native_sim](https://docs.zephyrproject.org/latest/boards/posix/native_sim/doc/index.html)
-   you develop very similar firmware for different devices and you only want one
    source code base for all of them. Differences between the device you want to
    abstract in board-specific files.


## Get list of defined board {#get-list-of-defined-board}

Basically by setting up a project like at <http://github.com/holgerschurig/multi-board-zepyhr>

You start there by reading the main [Makefile](http://github.com/holgerschurig/multi-board-zepyhr/Makefile) (for now, we ignore the boilerplate
Makefile.zephyr_init, that might be a future post).

You can think of this Makefile as --- mostly --- a list of small shell scripts,
combined into one Makefile, and accessible thus not via "`bin/foo.sh`" but via
"`make foo`". While some think that the syntax of Makefiles are arcane, it's
still nice enough to have them collect all kind of knowledge tidbits. And also,
occassionally, to use Make's ability of doing dependencies.


## Define boards in the Makefile {#define-boards-in-the-makefile}

So, if you want to compile the source, you simply run ...

```text
~/src/multi-board-zephyr$ make

-----------------------------------------------------------------------------

You must first select with with board you want to work:

native                configure for native (used for unit-tests)
nucleo                compile for STM32 Nucleo
local                 configure for locally defined board

-----------------------------------------------------------------------------
```

Oh, that didn't run too well. Basically the Makefile detected with

```text
all::
ifeq ("$(wildcard build/build.ninja)","")
	@$(call show_boards)
else
	ninja -C build
endif
```

The "`wildcard`" Makefile function determines if the `build/build.ninja`" already exists. If not, you'll see a list of all defined boards --- that is, if they are in your Makefile and have a section like this

```text
help help_boards::
	@echo "nucleo                compile for STM32 Nucleo"
```

to make them emit info about itself.


## Configure source for native simulation {#configure-source-for-native-simulation}

So now that we know that we first need to configure for one board, we select one board and run e.g.

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
-- CMake version: 3.28.1
-- Found Python3: /home/holger/src/multi-board-zephyr/.venv/bin/python3 (found suitable version "3.11.7", minimum required is "3.8") found components: Interpreter
-- Cache files will be written to: /home/holger/.cache/zephyr
-- Zephyr version: 3.5.99 (/home/holger/src/multi-board-zephyr/zephyr)
-- Found west (found suitable version "1.2.0", minimum required is "0.14.0")
-- Board: native_sim
-- Found host-tools: zephyr 0.16.4 (/home/holger/d/v73/.west/zephyr-sdk-0.16.4)
-- Found toolchain: host (gcc/ld)
-- Found Dtc: /home/holger/d/v73/.west/zephyr-sdk-0.16.4/sysroots/x86_64-pokysdk-linux/usr/bin/dtc (found suitable version "1.6.0", minimum required is "1.4.6")
-- Found BOARD.dts: /home/holger/src/multi-board-zephyr/zephyr/boards/posix/native_sim/native_sim.dts
-- Generated zephyr.dts: /home/holger/src/multi-board-zephyr/build/zephyr/zephyr.dts
-- Generated devicetree_generated.h: /home/holger/src/multi-board-zephyr/build/zephyr/include/generated/devicetree_generated.h
-- Including generated dts.cmake file: /home/holger/src/multi-board-zephyr/build/zephyr/dts.cmake
Parsing /home/holger/src/multi-board-zephyr/zephyr/Kconfig
Loaded configuration '/home/holger/src/multi-board-zephyr/zephyr/boards/posix/native_sim/native_sim_defconfig'
Merged configuration '/home/holger/src/multi-board-zephyr/prj.conf'
Merged configuration '/home/holger/src/multi-board-zephyr/native_sim.conf'
Configuration saved to '/home/holger/src/multi-board-zephyr/build/zephyr/.config'
Kconfig header saved to '/home/holger/src/multi-board-zephyr/build/zephyr/include/generated/autoconf.h'
-- Found GnuLd: /usr/bin/ld.bfd (found version "2.41.50")
-- The C compiler identification is GNU 13.2.0
-- The CXX compiler identification is GNU 13.2.0
-- The ASM compiler identification is GNU
-- Found assembler: /usr/bin/gcc
-- Configuring done (9.4s)
-- Generating done (0.0s)
-- Build files have been written to: /home/holger/src/multi-board-zephyr/build
-- west build: building application
ninja: no work to do.
west build
[1/93] Preparing syscall dependency handling

[3/93] Generating include/generated/version.h
-- Zephyr version: 3.5.99 (/home/holger/src/multi-board-zephyr/zephyr), build: zephyr-v3.5.0-3543-g89982b711bbd
...
make[1]: Leaving directory '/home/holger/src/multi-board-zephyr/build/zephyr'
[93/93] cd /home/holger/src/multi-board-zephyr/bui...ger/src/multi-board-zephyr/build/zephyr/zephyr.ex
(.venv) holger@holger:~/src/multi-board-zephyr$
```

And now we can run our source compiled against the (Zephyr included) native_sim board:

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

As you can see, this runs the unit-tests.


## Change configuration interactively {#change-configuration-interactively}

After you configured for any board (e.g. you have a `build/` directory), you can look or modify
Zephyr's configuration, use one of these:

-   `make xconfig`
-   `make menuconfig`

You can then compile. But should you ever re-configure your project, your
changes will be gone. Instead, modify some of the configuration files:


## Change configuration by {#change-configuration-by}

However, any change you do there will be forgotten if you re-configure your
source. To keep them permanent, modify one of the `*.conf` files. Since we're
still working with the native_sim board, we would therefore change
"`native_sim.conf`".

Use the following config files:

| Config file               | Purpose                                                        |
|---------------------------|----------------------------------------------------------------|
| native_sim.conf           | for the Zephyr-built-in native_sim board                       |
| nucleo_f303re.conf        | for the Zephyr-built-in nucleo_f303re board                    |
| boards/\*/\*/\*_defconfig | for a locally defined board                                    |
| prj.conf                  | for any configuration that is applicable to all of your boards |


## Compile for a "real" board {#compile-for-a-real-board}

Now we decide to compile our source against a "real" board, e.g. against the (Zephyr include) STM32 Nucleo:

```text
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
-- west build: making build dir /home/holger/src/multi-board-zephyr/build pristine
-- west build: generating a build system
Loading Zephyr default modules (Zephyr base).
-- Application: /home/holger/src/multi-board-zephyr
-- CMake version: 3.28.1
-- Found Python3: /home/holger/src/multi-board-zephyr/.venv/bin/python3 (found suitable version "3.11.7", minimum required is "3.8") found components: Interpreter
-- Cache files will be written to: /home/holger/.cache/zephyr
-- Zephyr version: 3.5.99 (/home/holger/src/multi-board-zephyr/zephyr)
...
[146/147] Linking C executable zephyr/zephyr.elf
Memory region         Used Size  Region Size  %age Used
           FLASH:       39782 B       512 KB      7.59%
             RAM:        9792 B        64 KB     14.94%
             CCM:          0 GB        16 KB      0.00%
        IDT_LIST:          0 GB         2 KB      0.00%
Generating files from /home/holger/src/multi-board-zephyr/build/zephyr/zephyr.elf for board: nucleo_f303re
[147/147] cd /home/holger/src/multi-board-zephyr/b...ger/src/multi-board-zephyr/build/zephyr/zephyr.el
```

This time, we get not an `"zephyr.exe`" file, but instead an ARM blob:

```text
:~/src/multi-board-zephyr$ file build/zephyr/zephyr.bin
build/zephyr/zephyr.bin: ARM Cortex-M firmware, initial SP at 0x20001fc0, reset at 0x08002f30, NMI at 0x08002bec, HardFault at 0x08002f1c, SVCall at 0x08003054, PendSV at 0x08002fec
```


## Compile for an out-of-tree board {#compile-for-an-out-of-tree-board}

So far, we only used boards that are brought to us via the Zephyr source code itself.

You can however also define your own board, outside of Zephyr, and compile against this board. In this
project, I named the board "`local`".

For this, you need to create a structure inside the `boards/` directory, e.g. like this:

```text
boards/arm/local/Kconfig.board
boards/arm/local/Kconfig.defconfig
boards/arm/local/board.cmake
boards/arm/local/local.dts
boards/arm/local/local.yaml
boards/arm/local/local_defconfig
boards/arm/local/support/openocd.cfg
```

The file "`local_defconfig`" is the equivalent of the "`*.conf`" files in the main directory.

Once you have this, you can reconfigure and build your source against this local target:

```text
:~/src/multi-board-zephyr$ make local
west build \
	--pristine \
	-b local \
	-o "build.ninja" \
	-- \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
	-DOVERLAY_CONFIG="boards/arm/local/local_defconfig" \
	-DBOARD_ROOT=.
-- west build: generating a build system
Loading Zephyr default modules (Zephyr base).
-- Application: /home/holger/src/multi-board-zephyr
...
[146/147] Linking C executable zephyr/zephyr.elf
Memory region         Used Size  Region Size  %age Used
           FLASH:       39544 B       512 KB      7.54%
             RAM:        9792 B        64 KB     14.94%
             CCM:          0 GB        16 KB      0.00%
        IDT_LIST:          0 GB         2 KB      0.00%
Generating files from /home/holger/src/multi-board-zephyr/build/zephyr/zephyr.elf for board: local
[147/147] cd /home/holger/src/multi-board-zephyr/b...ger/src/multi-board-zephyr/build/zephyr/zephyr.el
```

Note that the command line parameters to West are slightly different: the "`-DOVERLAY_CONFIG=boards/arm/local/local_defconfig`" argument points to our board file


## Compile only some files for some boards {#compile-only-some-files-for-some-boards}

In the main "`CMakeLists.txt`" you can specify that some files are only compiled
for some board. For example, one of your boards has GNSS; but other not. Then
you would do something like this:

```text
target_sources_ifdef(CONFIG_BOARD_LOCAL app PRIVATE
  local.c)

target_sources_ifdef(CONFIG_BOARD_LOCAL_GNSS app PRIVATE
  local.c
  gnss.c)
```

That is, the "`local.c`" source code will be compiled for both the boards
"local" and "local_gnss". But the latter, "=local_gnss.c" will also be compiled.
