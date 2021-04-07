+++
title = "ATmega328 von Raspberry aus programmieren"
tags = [ "RasPi", "Arduino", "ATmega", "SPI" ]
topics = [ "Elektronik" ]
date = "2016-03-28T17:48:46+02:00"
+++

Viele Leute kennen den ATmega von den Arduino-Projekten. Dort sind die
Prozessoren bereits mit einem sog. 'Bootloader' versehen, man kann sie
also über deren serielle Schnittstelle programmieren.

Was aber, wenn man einen "rohen" ATmega hat, frisch vom
Elektronikladen? Und außerdem kein AVR-Programmiergerät? Dann nimmt
man eben des Raspberry zum Programmieren!

<!--more-->

In der Zeitschrift "Funkamateur 2/2016" ist ein ähnlicher Artikel
enthalten. Aber der dort getriebene Aufwand ist wesentlich höher.
Beispielsweise wird ein Darlington-Array `ULN2803` gebraucht, und die
Programmierung erfolgt auch nicht (auf Raspberry-Seite) über SPI und
einem Standardprogramm, sondern über GPIOs und einem Python-Programm.


## Schaltung

Die Grundschaltung eines ATmega328 ist einfach:

* `VCC` (Pin 7) mit 3.3V verbinden. Theoretisch sollte man noch `AVCC`
  (Pin 20) mit 3.3V verbinden, zum Programmieren brauchte ich das aber
  nicht.
* `GND` (Pin 8) mit Masse verbinden. Theoretisch sollte man auch noch das
  andere `GND` (Pin 22) mit Masse verbinden. Bei mir war das aber zum
  Programmieren nicht nötig.
* ein Kondensator `C1` mit 100nF als Abblockkondensator nahe an Pins 7
  und 8.
* 16 MHz-Quarz an Pins 9 und 10
* von jedem Quarz-Pin ein 22pF Kondensator nach Masse führen
* `nRESET` über einen Pull-Up-Widerstand von 10 kOhm nach `VCC`. Später
  merkte ich, das noch nicht mal der Pull-Up-Widerstand wirklich nötig
  ist ...

Obige Grundschaltung findet man immer und immer wieder.

Nun wollen wir den ATmega jedoch programmieren, also müssen wir einige
Bahnen vom Raspberry zum ATmega ziehen:

* gelb: `GPIO25` nach `nRESET`
* cyan: `GPIO10`/`SPI0_MOSI` nach `D11`/`MOSI`
* lila: `GPIO9`/`SPI0_MISO` nach `D12`/`MISO`
* grün: `GPIO11`/`SPI_CLK` nach `D13`/`SCK`

Die erste (gelbe) Leitung ist zum Resetten des ATmega.

Die anderen drei Leitungen sind SPI-Leitungen, mit denen der Raspberry
den AVR programmieren kann.

<img src="schema.png" class="pure-img">

## Software

### AVRdude installieren

Auf dem Raspberry brauchen wir die Software `avrdude`:

``` keepit
pi@raspberrypi:~ $ sudo su
root@raspberrypi:/home/pi# apt-get install avrdude
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following extra packages will be installed:
  libftdi1
Suggested packages:
  avrdude-doc
The following NEW packages will be installed:
  avrdude libftdi1
0 upgraded, 2 newly installed, 0 to remove and 12 not upgraded.
Need to get 260 kB of archives.
After this operation, 1,021 kB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://archive.raspberrypi.org/debian/ jessie/main avrdude armhf 6.1-2+rpi1 [244 kB]
Get:2 http://mirrordirector.raspbian.org/raspbian/ jessie/main libftdi1 armhf 0.20-2 [16.7 kB]
Fetched 260 kB in 1s (182 kB/s)                              
Selecting previously unselected package libftdi1:armhf.
(Reading database ... 126952 files and directories currently installed.)
Preparing to unpack .../libftdi1_0.20-2_armhf.deb ...
Unpacking libftdi1:armhf (0.20-2) ...
Selecting previously unselected package avrdude.
Preparing to unpack .../avrdude_6.1-2+rpi1_armhf.deb ...
Unpacking avrdude (6.1-2+rpi1) ...
Processing triggers for man-db (2.7.0.2-5) ...
Setting up libftdi1:armhf (0.20-2) ...
Setting up avrdude (6.1-2+rpi1) ...
Processing triggers for libc-bin (2.19-18+deb8u3) ...
```

Ältere Tutorials reden davon, das man den AVRdude selbst compilieren
solle. Das ist aber mittlerweile nicht mehr nötig. Mein Raspberry
läuft Raspian 8.0, also basierend auf Debian Jessie. Und die
avrdude-Version **6.1** funktioniert einwandfrei.


### Chip erkennen

Hat man alles richtig verdrahtet, sollte der Chip erkannt werden:

``` keepit
root@raspberrypi:~# avrdude -c linuxspi -p m328p -P /dev/spidev0.0 
avrdude: AVR device initialized and ready to accept instructions
Reading | ################################################## | 100% 0.00s
avrdude: Device signature = 0x1e950f
avrdude: safemode: Fuses OK (E:07, H:D9, L:62)
avrdude done.  Thank you.
```

Die Device-Signatur 0x1e950f steht für den ATmega328**P**, also exakt
für den Chip, den ich mir gekauft hatte.


Sollte kein `/dev/spidev0.0` vorhanden sein, muss `raspi-config`
starten und unter "Advanced Options" SPI aktivieren.

### Takt senken

Bei mir ging es danach aber dennoch noch nicht. Erst als ich den
SPI-Takt von 400 kHz auf 200 kHz gesenkt hatte, lief es. Das ist zwar
deutlich langsamer als vorher, aber immer noch schneller als mit
GPIO-"Bitbanging".


Dazu in `/etc/avrdude.conf` den Eintrag `linuxspi` so ändern:

``` keepit
programmer
  id = "linuxspi";
  desc = "Use Linux SPI device in /dev/spidev*";
  type = "linuxspi";
  reset = 25;
  baudrate=200000;
;
```

Nun hat's funktioniert. Ich vermute, das meine Kabel vom Raspberry zum
Breadboard mit dem ATmega zu lang waren.
