+++
title = "Serial setup with C-Kermit"
categories = [ "Linux" ]
tags = [ "Kermit", "Miniterm", "Putty", "Serial" ]
date = "2016-04-01"
+++

When you work with embedded devices (e.g. SabreLite, [Arduino][a],
[Raspberry Pi][r]) you often need to work over a serial port, e.g. to
customize the Barebox or U-Boot boot loader.

[a]: /tags/arduino/
[r]: /tags/raspi/

On Linux, people often use "*minicom*" for this. Other options are
"*Putty*" (yes, it's not a Windows-only program, try "`apt-get install
putty`") or even the ancient [C-Kermit](http://www.kermitproject.org).
Surprisingly I found that Kermit suits my work-flow the best, when
properly configured.

<!--more-->

The reason: Kermit doesn't come into my way. No menu, no
interpretation of escape codes (so urxvt does that), no nothing.


## Installation

On Debian, installation is as easy as:

```shell
apt-get install ckermit
```


## Configuration

Place this into `~/.kermrc`:

```none
set line /dev/ttyS0
set baud 115200
set handshake none
set flow-control none
set carrier-watch off
set escape-character ^X
log session ~/.kermlog
connect

```

- set serial port (if you don't have a real RS232, use `/dev/ttyUSB0`
  instead)
- set baud rate. We have the year 2016, so there's no need to run
  anything slower than 115200 baud nowadays. Even Windows 7 (or newer)
  can nowadays use this baud rate.
- turn all handshaking off. Embedded devices often only use 3 wires
  (`RXD`, `TXD` and `GND`) for their communications anyway.
- for the same reason, turn of carrier detection
- allow "`Ctrl-X`" as an escape character
- write a log of the whole transaction to `~/.kermlog`
- and connect


## Keyboard control

When I want to disconnect, I type "`Ctrl-X q`" (q like quit).

If i ever want to get to Kermit command prompt (which I almost never
do), then "`Ctrl-X c`" does the trick.


## Example

```none
schurig@desktop:~$ kermit
Connecting to /dev/ttyS0, speed 115200
 Escape character: Ctrl-X (ASCII 24, CAN): enabled
Type the escape character followed by C to get back,
or followed by ? to see other options.
Session Log: /home/schurig/.kermlog, text (0) 
----------------------------------------------------
Barebox: version 2015.12.0, git 2016-03.1-84-g18146e8
info: FPGA v35
info: CPU board v5
info: Front board v8
info: MIL connector board v1
info: Expansion board v0
info: strap-id forces DVB2A/BUCK2 for LCD
info: PIC .10:  boot v0.0, application v0.6

Interrupt boot with any command:  3

Helpful commands:

	help  and  help <COMMAND>
	boot sdcard
	boot emmc

barebox:/
```
