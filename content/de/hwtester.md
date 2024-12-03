+++
title = "flexibler Hardware-Tester für x86-Systeme: hwtester"
author = ["Holger Schurig"]
date = 2024-01-18
tags = ["linux", "kernel", "systemd", "make", "debian", "dpkg", "eatmydata"]
categories = ["job"]
draft = false
+++

Hier geht es darum, frisch produzierte Geräte der Klassen DLT-V83 und DLT-V72
auf Herz und Nieren zu prüfen.

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Projekt-Info](#projekt-info)
- [Anforderungen](#anforderungen)
- [Image erstellen](#image-erstellen)
- [automatisiert USB-Stick erstellen](#automatisiert-usb-stick-erstellen)
- [Tests](#tests)
    - [Testplätze](#testplätze)
    - [Testarten](#testarten)
    - [Geräte](#geräte)
    - [Aufbau der Tests](#aufbau-der-tests)
- [Kommunikation mit Test-Fixture](#kommunikation-mit-test-fixture)
- [Testreport abspeichern](#testreport-abspeichern)
- [Verwandte Projekte](#verwandte-projekte)

</div>
<!--endtoc-->

<div class="job">

In Beiträgen der Kategorie [Job](/categories/job/) trage ich Projekte zusammen, die ich im Rahmen
meiner beruflichen Karriere federführend durchgeführt habe. Ich gehe dabei mit
Absicht nicht allzu sehr auf Details an: die Interessen meiner Arbeitgeber sollen
ja nicht berührt werden.

</div>


## Projekt-Info {#projekt-info}

Idee: Leiter der Elektronikentwicklung

Umsetzung: ich (Programmierung), allerdings mit viel Input von der Fertigung, Reparatur-Abteilung und Qualitätssicherung --- ein echtes Team-Projekt

Nutzung: 2013 bis heute

Implementierung: Combined-Linux, Bash, Python, C, C++

Effizienzgewinn:

-   erstmals wurden alle hergestellten Geräte systematisch und reproduzierbar getestet
-   viele Produktionsfehler wurden frühzeitig herausgefunden, teilweise schon beim
    Lieferanten der Hauptplatine
-   für jedes Gerät und Test gab es einen Testreport, da war die
    Qualitätssicherung sehr erfreut


## Anforderungen {#anforderungen}

-   bootet von einem USB-Stick beliebiger Größe
-   musst an verschiedenen Testorten verschiedene Tests (automatisch) aktivieren bzw. deaktivieren
-   muss verbaute Hardware weitestgehend erkennen
-   32bit wg. externer Test-Tools
-   die kommerzielle Testsoftware "Toolstar TestLX" musste eingebunden werden
-   **keine** Anbindung an die Auftragsverwaltung (wurde so nicht gewünscht)


## Image erstellen {#image-erstellen}

Das Image wird dem Tool

[ automatisch Images erstellen ]({{< relref "mkimage" >}})

erstellt. Statt nur
"`bin/run`" auszuführen wird gibt man einfach eine Konfigurationsdatei an:

```text
~/d/mkimage$ bin/run -c conf/hwtester.imgconf
```


## automatisiert USB-Stick erstellen {#automatisiert-usb-stick-erstellen}

Anschließend hat man das Image im Verzeichnis "`image.hwtester/`". Doch wie bringt man das nun auf einen Stick?
Indem wir es eine Image verwandeln:

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--0a417f }
# make -n hda
rm -f hda
fallocate -l 640M hda
dd bs=440 conv=notrunc count=1 if=/usr/lib/EXTLINUX/gptmbr.bin of=hda.hwtester
sgdisk hda --new 1::600M --typecode=1:8300   # 8300: Linux filesystem
sgdisk hda --change-name=1:"Linux filesystem"
sgdisk hda --partition-guid=1:6f8f4e09-84df-3804-1c41-38f20001b6c8
sgdisk hda --attributes 1:set:2
losetup -D
kpartx -sva hda
losetup /dev/loop1 /dev/mapper/loop0p1
mke2fs -j /dev/loop1
tune2fs -i 0 /dev/loop1
tune2fs -c 0 /dev/loop1
sync
losetup -d /dev/loop1
kpartx -sd hda
```

-   Zeile [2](#org-coderef--0a417f-2): zuerst löschen wir eine eventuelle alte "`hda`" Datei
-   Zeile [3](#org-coderef--0a417f-3): dann wird eine neue angelegt. 640 MB reichen dicke aus. Wir
    verwenden fallocate, weil es schneller als "`dd if=/dev/zero ...`" ist. Es
    alloziert nur die Blöcke, beschriebt sie aber nicht. Der Linux-Kernel selbst
    sorgt dafür, das nur 0x00 Bytes enthalten sind.
-   Zeile [4](#org-coderef--0a417f-4): nun wird aus dem Host-System der EXTLINUX Bootloader an die
    richtige Position der "`hda`"-Datei kopiert. "EXTLINUX" ist weniger komplex
    als Grub und für Industrieanwendungen vorzuziehen.
-   Zeile [5](#org-coderef--0a417f-5): nun wird mit "`sgdisk`" eine GPT-Partition **in der Datei** "`hda`"
    erstellt.
-   Zeile [9](#org-coderef--0a417f-9): falls man früher noch ein Loopback-Mount hat, wird dies hier
    zur Sicherheit mit [losetup](https://manpages.debian.org/bookworm/mount/losetup.8.en.html) gelöscht
-   Zeile [10](#org-coderef--0a417f-10): der Befehl [kpartx](https://manpages.debian.org/bookworm/kpartx/kpartx.8.en.html) macht nun die normale Datei "`hda`" dem
    Kernel bekannt. Er denkt nun sozusagen, das diese Datei ein Blockdevice ist.
    Der Kernel ließt die Partition von "`hda`" und erstellt
    für jede Partition ein Loopback-Device in "`/dev/mapper/`".
-   Zeile [11](#org-coderef--0a417f-11): dieses Partition-Loopback-Device mappen wir nun mit [losetup](https://manpages.debian.org/bookworm/mount/losetup.8.en.html), damit wir
    darauf zugreifen können: nun ist Filesystem erstellen oder auch Mounten möglich
-   Zeile [12](#org-coderef--0a417f-12): diese Partition wird nun mit ext4 formatiert. Nicht durch
    den Namen des Binaries, "`mke2fs`" beirren lassen: das "`-j`" sorgt dafür, das
    ein Journalling-Filesystem angelegt wird, und das ist schon seit Jahren per
    Default ext4.
-   Zeile [13](#org-coderef--0a417f-13): damit die Mitarbeiter in der Produktion nicht auf irgendwelche
    fsck's warten müssen, wird das Interval- und Zeitbasierte Prüfen des
    Filesystems ausgeschaltet. Es ist sowieso nicht möglich, da der Stick sowieso
    mit einem [ dynamischen Flash-Schutz ]({{< relref "dynamischer-flashschutz" >}}) vor
    Schreibzugriffen geschützt ist
-   am Schluss löschen wir das loopback-Device und sagen dem Kernel, das "`hda`"
    nun nichts besonderes mehr ist ... nur eine Datei

Ein weiteres Makefile-Target ...

```text
# make -n image2hda
...
```

... nutzt ebenfalls  [losetup](https://manpages.debian.org/bookworm/mount/losetup.8.en.html) und  [kpartx](https://manpages.debian.org/bookworm/kpartx/kpartx.8.en.html). Aber statt "`tune2fs`" wird dann "`/dev/loop1`"
einfach nach "`/mnt`" gemounted und mit "`rsync`" wird alles von "`image.hwtester/`" dorthin
synchronisiert. Da dies aber alles trivial ist, lasse ich es mal aus.

Übrigens: die Datei "`hda`" ist sehr klein, sie kann auf 1 GB bis 32 GB Sticks
geschrieben werden:

```text
# lsblk
...
# cat hda >/dev/sdc
```

Übrigens: zum Kopieren von Images auf Sticks braucht man kein "`dd`" unter
Linux. Der ganz normale "`cat`" Befehl tut es auch. Und er hat eine durchaus
nettere Syntax :-)

Übrigens 2: Beim ersten Booten wird passt der Stick seine eigene Partition
dynamisch auf die echte Stickgröße an. USB-Sticks haben ja unterschiedliche
echte Größen, bedingt durch Bad-Sector-Management direkt auf dem Stick. Uns
stört das aber nicht.


## Tests {#tests}

Nun haben wir also einen bootenden USB-Stick. Und dort befinden sich in
"`/usr/local/hwtester`" alle Test-Scripte, -Binaries etc. Doch bevor wir auf die
eigentlichen Tests eingehen, müssen wir erst einige Konzepte einführen.


### Testplätze {#testplätze}

Hiermit ist nicht gemeint, ob in der Pruduktion 4 oder 8 Leute Geräte zusammenbauen.

Sondern die verschiedenen Orte, an denen wir Testen möchten:

-   nach der Produktion der Hauptplatine --- dies sollte schon beim Herstellungsort
    geschehen, um aufwändige Rückliefergen vorzubeugen. Zu diesem Zeitpunkt gibt es
    aber keine Front-Platine (Display, Fronttasten, Touch, Defroster). Daher dürfen
    Tests dafür hier nicht ablaufen
-   Endgerätefertigung nach Kundenwunsch: hier wird ein Mainboard mit der gewünschten
    Front zusammengeführt. Je nach Auftrag kann das 10", 12" oder 15" sein. Verschiedene
    LCD-Aufläsungen. Verschiedene Anzahl von Tasten auf der Front. Da diese Geräte hinterher
    an den Kunden gehen, gibt es auch Sichtprüfungen ("Hat die Lackierung einen Kratzer?")
-   Service: auch hier sollten Tests ausführbar, aber i.d.R. manuell. Auch dürfen diese Tests
    keinerlei Änderungen durchführen. Also nicht automatisch "Oh, das BIOS ist veraltet,
    ich flash da mal ein Neues drauf". Der Grund liegt darin, das manche Kunden die Geräte
    in EXAKT der abgenommenen Konfiguration haben wollen, einschließlich der BIOS-Version

Man kann nun jeden Test einzeln an einen oder mehrere Testorte (auch an alle) binden.


### Testarten {#testarten}

Naturgemäß gibt es mehrere Tests

-   automatische Tests: diese liebt der Leiter der Fertigung. Sie laufen
    vollautomatisch ab, oft in Sekundenbruchteilen. Sie sind daher (nahezu)
    kostenneutral. Nahezu, weil man für einige dieser Test vorher die passenden
    Teststecker einstecken muss. Beispiel: Prüfen der seriellen Schnittstelle.
    Automatische Tests werden einer nach den anderen ausgeführt.
-   manuelle Tests: hier geht es um Dinge, die man nicht automatisieren kann ---
    oder deren Automatisierung zwar an sich möglich ist, sich aber aufgrund der
    Stückzahlen nicht lohnt. Beispiel: obige "Hat das Gehäuse einen Kratzer?"
    Abfrage. Auch manuelle Tests werden einer nach den anderen ausgeführt.
-   optionale Tests: manchmal ist eine Hardware nur für machen Kunden verbaut,
    aber nicht generell. Also muss z.B. der CAN-Test nicht immer ausgeführt
    werden. Diese Tests müssen per Menü per Hand ausgewählt werden.

Man weist nun jeden Test eine Testart zu. Diese kann auch verschieden sein:
viele automatische Tests der Produktion sind optionale Tests im Service.


### Geräte {#geräte}

Bedingt durch die Hardware-Erkennung des zugrundeliegenden
"[ Combined-Linux: ein Image für viele Geräte ]({{< relref "combined-linux" >}})" läuft
der Teststick auf viele Gerätetypen und Varianten. Aber ein i2c-Test für den
DLT-V83 muss natürlich nach anderen Devices suchen als einer für den DLT-V72.

Man weist nun jeden Test eine oder mehrere Geräte zu.

Auch kann man einen Test an eine USB- oder PCI-ID binden.


### Aufbau der Tests {#aufbau-der-tests}

Jeder Test ist ein einzelnes File im "`tests/`" Verzeichnis, für sich abgeschlossen. Die
Komplexität der Tests ist i.d.R. gering, zwischen 10 und 330 Programmzeilen. Je nach dem,
was einfacher war, wurden sie in Bash oder Python geschrieben.

Jeder Test hat speziell formatierte Kommentare, die Testorte, Testarten und Geräte definieren.
Hier ein Beispiel für "`report_cpu_snr.sh`":

```sh
#!/bin/bash

# Test: auto everywhere G7I??C??

. lib.sh

head "CPU board serial number"

./amidelnx_26_32 /BS | grep Done || error "cannot get SNR"

ok "done"
```

Das ist ein automatischer Test, der an jedem Testort ausgeführt werden soll,
jedoch nur für die Geräteklasse G7I??C??.

Derselbe "`^# Test:`"-Marker würde auch in einem Python-Test verwendet werden.
Dort werden meist komplexere Dinge getestet, welche in Bash nicht so einfach zu
lösen sind. Hier ein Beispiel:

```python
#!/usr/bin/python2.7
# -*- coding: utf-8 -*-

# Test: auto everywhere M7I??A??
# Test: auto everywhere G7I?????

from lib import *
from glob import glob

head("CPU temperature in range?")


WANTSMIN = 20
WANTSMAX = 65

def acpitz():
  ...
def coretemp():
  ...

if hwmatch("M7I??A??"):
  value = acpitc()
else:
  value = coretemp()

if value < WANTSMIN:
        error("CPU temperature too low: %.1f °C" % value)
if value > WANTSMAX:
        error("CPU temperature too high: %.1f °C" % value)

ok("CPU temperature between %d and %d: %.1f" % (WANTSMIN, WANTSMAX, value))
```

Jaaaa, hier wird noch Python 2.7 verwendet. Bei Projektstart war Python 3 noch
nicht soweit.


## Kommunikation mit Test-Fixture {#kommunikation-mit-test-fixture}

Am Produktionsplatz der Hauptplatine für den DLT-V83 gab es auch ein
Test-Fixture. Dieses hat mit dem Teststick über ein serielles Kabel
kommunuziert. Die Testsoftware dort hat dann bei mir z.B. "Mach mal ordentlich
CPU-Last" angefordert und dann z.B. den aufgenommenen Strom gemessen, während
mein Testprogramm die Coretemp währenddessen gemessen hat.


## Testreport abspeichern {#testreport-abspeichern}

Nachdem alle Tests durchgeführt gab, hat der Produktionsmitarbeiter "Finalize
Tests" ausgeführt. Damit wurde dann ein Testprotokoll per SMB oder FTP auf einem
Server im Produktionsnetz (vom Firmennetz getrennt!) gespeichert.

Dort waren natürlich alle Testergebisse, aber man konnte auch nachvollziehen
oder ein optionaler Test ausgeführt worden ist ... oder nicht.

Neben reinen Testergebnissen wurden dort auch viele Informationen abgespeichert,
beispielsweise die MAC-Adresse der Ethernet- und WIFI-Ports --- so haben wir
z.B. bemerkt, das wir einmal viele Mainboards mit identischen MAC-Adressen
geliefert bekamen.


## Verwandte Projekte {#verwandte-projekte}

Die folgenden Projekte sind mit dem "`hwtester`" verwandt, weil er entweder
darauf aufbaut, es nutzt oder das Projekt extrem ähnlich ist.

-   [ Combined-Linux: ein Image für viele Geräte ]({{< relref "combined-linux" >}})
-   [ automatisch Images erstellen ]({{< relref "mkimage" >}})
-   [ Dynamischer Flash-Schutz ]({{< relref "dynamischer-flashschutz" >}})
-   TODO(Artikel schreiben) Hardware-Teststick für DLT-V73

Die Projekte, die mit diesem Tool erstellte Images verwenden zähle ich jetzt mal
nicht auf :-)
