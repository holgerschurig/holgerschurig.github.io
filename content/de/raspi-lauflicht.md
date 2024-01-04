+++
title = "Lauflicht mit Raspberry und 74HC595"
date = "2016-03-06T12:32:10+01:00"
tags = [ "RasPi", "74HC595", "GPIO", "SPI" ]
categories = [ "Elektronik" ]
+++

Bei dieser Schaltung geht es mir weniger darum, 8 LEDs zu betreiben.
Die kann man nämlich auch direkt am Raspberry Pi anschließen. Sondern
es geht darum, mit den Schieberegister 74HC595 zu experimentieren.

Dieses steuere ich zunächst durch diverse GPIO Ports an.

Und danach betreibe ich es am SPI-Port des RasPi. Das funktioniert
wunderbar, obwohl der Text "SPI" nirgendwo im 74HC595-Datenblatt
auftaucht :-)

<!--more-->

## Schaltung

<img src="raspi-lauflicht-schem.png" class="pure-img">

Die Schaltung ist einfach:

* der 74HC595 bekommt `VCC` und `GND`. Da es ein HC-Chip ist, kann er
  anders als normale TTL-Bausteine direkt mit 3.3V betrieben
  werden. Das ist wichtig, da der Raspberry Pi **nicht** 5V-tolerant
  ist.
* `nOE` (negative Output Enable) geht an `GND`. Der '595 halt also
  immer ein Output Enable.
* `nMR` (Master Reclear) geht and `VCC`. Damit wird also der '595 nie
  zurückgesetzt.
* `SH_CP` (Shift Register Clock Pin) geht an das Signal `SPI0_SCLK`, also die
  Clock des SPI0.
* `ST_CP` (Storage Register Clock Pin) geht `SPI0_CE0`, also an das Chip Enable 0
   Signal des SPI0 Busses.
* `DS` (Data Serial Input) geht an das Signal `SPI0_MOSI`, also den seriellen
  Ausgang von SPI0.
  
Das war schon das ganze Interface zwischen '595 und Raspberry.

Nach "oben" zu den LEDs haben wir 8 Ausgabe, `Q0` bis `Q7`. Der
Einfachheit halber habe ich nur zwei LEDs eingezeichnet.

Auch war ich sparsam: ich habe einfach nur einen passenden,
gemeinsamen Vorwiderstand von 220 Ohm eingebaut. Damit sind die LEDs
unterschiedlich hell wenn man mal mehr als eine LED anschaltet. Da es
mir aber darum ging, den '595 und SPI zu verstehen, war mir das egal.
Ansonsten hätte ich eine Konstantstromquelle vorgesehen.


## Verdrahtung

<img src="raspi-lauflicht-bb.png" class="pure-img">

Auch in die Verdrahtung habe ich nur 2 von 8 LEDs eingetragen.


## Software für GPIO

Zunächst habe ich das ganze via GPIO, also per "Big Banging" betrieben. Das geht so:

``` python
#!/usr/bin/python

import sys, time

SPEED = 0.04

import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)


# Nebeneinander liegende GPIOs:
# DATA   = 22 # DS
# LATCH  = 27 # STCP
# CLOCK  = 17 # SHCP

# Die Pins von SPI0 nutzend, aber noch als GPIO benutzt:
DATA    = 10 # SPI0_MOSI
LATCH   = 8  # SPI0 CS0
CLOCK   = 11 # SPI0 CLK

def setup():
	GPIO.setmode(GPIO.BCM)
	GPIO.cleanup()
	GPIO.setup(DATA,  GPIO.OUT)
	GPIO.setup(CLOCK, GPIO.OUT)
	GPIO.setup(LATCH, GPIO.OUT)
	GPIO.output(DATA,  False)  # Databit to be shifted into the register
	GPIO.output(LATCH, False)  # Latch is used to output the saved data
	GPIO.output(CLOCK, False)  # Used to shift the value of DATAIN to the register

def shift(dat):
	GPIO.output(DATA,  dat)
	GPIO.output(CLOCK, GPIO.HIGH)
	GPIO.output(CLOCK, GPIO.LOW)

def writeout():
	GPIO.output(LATCH, GPIO.HIGH)
	# time.sleep(icsleep)
	GPIO.output(LATCH, GPIO.LOW)

def shiftnum(dat):
	for i in range(8):
		shift(dat & 0x80 != 0)
		dat <<= 1
	writeout()

setup()

def run_down():
	n = 0x01
	while n < 0x100:
		shiftnum(n)
		time.sleep(SPEED)
		n <<= 1

def run_up():
	n = 0x80
	while n:
		shiftnum(n)
		time.sleep(SPEED)
		n >>= 1

def run_pattern(pattern, speed=0.08):
	for n in pattern:
		shiftnum(n)
		time.sleep(speed)

try:
	while True:
		run_down()
		run_up()
		# run_pattern((
		# 	0x80 | 0x04,
		# 	0x40 | 0x08,
		# 	0x20 | 0x10,
		# 	0x10 | 0x20,
		# 	0x08 | 0x40,
		# 	0x04 | 0x80,
		# 	0x02 | 0x01,
		# 	0x01 | 0x02))

except KeyboardInterrupt:
	print

```

## Software für SPI

Aber am meisten hatte ich mich für SPI interessiert. Dieses Programm
erbrachte dann das gewünschte Ergebnis:

``` python
#!/usr/bin/python

import sys, time
import spidev

spi = spidev.SpiDev()
spi.open(0, 0)    # Port 0, Chip Select 0

n = 1
while True:
	spi.writebytes([n])
	time.sleep(0.04)
	n <<= 1
	if n == 0x100:
	    n = 1

```

Funktionen wie `run_down`, `run_up` habe ich mir hier gespart, sie
funktionieren im Prinzip genauso wie beim GPIO-Beispiel.

Und, wie man sieht: die eigentliche Ausgabe in das Schieberegister ist
wesentlich einfacher.
