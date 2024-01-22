+++
title = "flexibler Hardware-Tester für x86-Systeme: hwtester"
author = ["Holger Schurig"]
date = 2024-01-18
tags = ["linux", "kernel", "systemd", "make", "debian", "dpkg", "eatmydata"]
categories = ["job"]
draft = false
+++

Hier geht es darum, frisch produzierte Geräte der Klassen DLT-V83 und DLT-V72 <br/>
auf Herz und Nieren zu prüfen. <br/>

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
- [Dazugehörige Projekte](#dazugehörige-projekte)

</div>
<!--endtoc-->

<div class="job">

In Beiträgen der Kategorie [Job](/categories/job/) trage ich Projekte zusammen, die ich im Rahmen <br/>
meiner beruflichen Karriere federführend durchgeführt habe. Ich gehe dabei mit <br/>
Absicht nicht allzusehr auf Details an: die Interessen meiner Arbeitgeber sollen <br/>
ja nicht berührt werden. <br/>

</div>


## Projekt-Info {#projekt-info}

Idee: Leiter der Elektronikentwicklung <br/>

Umsetzung: ich (Programmierung), allerdings mit viel Input von der Fertigung, Reparatur-Abteilung und Qualitätssicherung --- ein echtes Team-Projekt <br/>

Nutzung: 2013 bis heute <br/>

Implementierung: Combined-Linux, Bash, Python, C, C++ <br/>

Effizienzgewinn: <br/>

-   erstmals wurden alle hergestellten Geräte systematisch und reproduzierbar getestet <br/>
-   viele Produktionsfehler wurden frühzeitig herausgefunden, teilweise schon beim <br/>
    Lieferanten der Hauptplatine <br/>
-   für jedes Gerät und Test gab es einen Testreport, da war die <br/>
    Qualitätssicherung sehr erfreut <br/>


## Anforderungen {#anforderungen}

-   bootet von einem USB-Stick beliebiger Größe <br/>
-   musst an verschiedenen Testorten verschiedene Tests (automatich) aktivieren bzw. deaktivieren <br/>
-   muss verbaute Hardware weitestgehend erkennen <br/>
-   32bit wg. externer Test-Tools <br/>
-   die kommerzielle Testsoftware "Toolstar TestLX" musste eingebunden werden <br/>
-   **keine** Anbindung an die Auftragsverwaltung (wurde so nicht gewünscht) <br/>


## Image erstellen {#image-erstellen}

Das Image wird dem Tool <br/>

[ automatisch Images erstellen ]({{< relref "mkimage" >}}) <br/>

erstellt. Statt nur <br/>
"`bin/run`" auszuführen wird gibt man einfach eine Konfurationsdatei an: <br/>

```text
~/d/mkimage$ bin/run -c conf/hwtester.imgconf
```


## automatisiert USB-Stick erstellen {#automatisiert-usb-stick-erstellen}

Anschließend hat man das Image im Verzeichnis "`image.hwtester/`". Doch wie bringt man das nun auf einen Stick? <br/>
Indem wir es eine Image verwandeln: <br/>

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

-   Zeile [2](#org-coderef--0a417f-2): zuerst löschen wir eine eventualle alte "`hda`" Datei <br/>
-   Zeile [3](#org-coderef--0a417f-3): dann wird eine neue angelegt. 640 MB reichen dicke aus. Wir <br/>
    verwenden fallocate, weil es schneller als "`dd if=/dev/zero ...`" ist. Es <br/>
    alloziert nur die Blöcke, beschriebt sie aber nicht. Der Linux-Kernel selbst <br/>
    sorgt dafür, das nur 0x00 Bytes enthalten sind. <br/>
-   Zeile [4](#org-coderef--0a417f-4): nun wird aus dem Host-System der EXTLINUX Bootloader an die <br/>
    richtige Position der "`hda`"-Datei kopiert. "EXTLINUX" ist weniger komplex <br/>
    als Grub und für Industrieanwendungen vorzuziehen. <br/>
-   Zeile [5](#org-coderef--0a417f-5): nun wird mit "`sgdisk`" eine GPT-Partition **in der Datei** "`hda`" <br/>
    erstellt. <br/>
-   Zeile [9](#org-coderef--0a417f-9): falls man früher noch ein Loopback-Mount hat, wird dies hier <br/>
    zur Sicherheit mit [losetup](https://manpages.debian.org/bookworm/mount/losetup.8.en.html) gelöscht <br/>
-   Zeile [10](#org-coderef--0a417f-10): der Befehl [kpartx](https://manpages.debian.org/bookworm/kpartx/kpartx.8.en.html) macht nun die normale Datei "`hda`" dem <br/>
    Kernel bekannt. Er denkt nun sozusagen, das diese Datei ein Blockdevice ist. <br/>
    Der Kernel ließt die Partition von "`hda`" und erstellt <br/>
    für jede Partition ein Loopback-Device in "`/dev/mapper/`". <br/>
-   Zeile [11](#org-coderef--0a417f-11): dieses Partition-Loopback-Device mappen wir nun mit [losetup](https://manpages.debian.org/bookworm/mount/losetup.8.en.html), damit wir <br/>
    darauf zugreifen können: nun ist Filesystem erstellen oder auch Mounten möglich <br/>
-   Zeile [12](#org-coderef--0a417f-12): diese Partition wird nun mit ext4 formatiert. Nicht durch <br/>
    den Namen des Binaries, "`mke2fs`" beirren lassen: das "`-j`" sorgt dafür, das <br/>
    ein Journalling-Filesystem angelegt wird, und das ist schon seit Jahren per <br/>
    Default ext4. <br/>
-   Zeile [13](#org-coderef--0a417f-13): damit die Mitarbeiter in der Produktion nicht auf irgendwelche <br/>
    fsck's warten müssen, wird das Interval- und Zeitbasierte Prüfen des <br/>
    Filesystems ausgeschaltet. Es ist sowieso nicht möglich, da der Stick sowieso <br/>
    mit einem [ dynamischen Flash-Schutz ]({{< relref "dynamischer-flashschutz" >}}) vor <br/>
    Schreibzugriffen geschützt ist <br/>
-   am Schluss löschen wir das loopback-Device und sagen dem Kernel, das "`hda`" <br/>
    nun nichts besonderes mehr ist ... nur eine Datei <br/>

Ein weiteres Makefile-Target ... <br/>

```text
# make -n image2hda
...
```

... nutzt ebenfalls  [losetup](https://manpages.debian.org/bookworm/mount/losetup.8.en.html) und  [kpartx](https://manpages.debian.org/bookworm/kpartx/kpartx.8.en.html). Aber statt "`tune2fs`" wird dann "`/dev/loop1`" <br/>
einfach nach "`/mnt`" gemounted und mit "`rsync`" wird alles von "`image.hwtester/`" dorthin <br/>
synchronisiert. Da dies aber alles trivial ist, lasses ich es mal aus. <br/>

Übrigens: die Datei "`hda`" ist sehr klein, sie kann auf 1 GB bis 32 GB Sticks <br/>
geschrieben werden: <br/>

```text
# lsblk
...
# cat hda >/dev/sdc
```

Übrigens: zum Kopieren von Images auf Sticks braucht man kein "`dd`" unter <br/>
Linux. Der ganz normale "`cat`" Befehl tut es auch. Und er hat eine durchaus <br/>
nettere Syntax :-) <br/>

Übrigens 2: Beim ersten Booten wird passt der Stick seine eigene Partition <br/>
dynamisch auf die echte Stickgröße an. USB-Sticks haben ja unterschiedliche <br/>
echte Größen, bedingt durch Bad-Sector-Management direkt auf dem Stick. Uns <br/>
stört das aber nicht. <br/>


## Tests {#tests}

Nun haben wir also einen bootenden USB-Stick. Und dort befinden sich in <br/>
"`/usr/local/hwtester`" alle Test-Scripte, -Binaries etc. Doch bevor wir auf die <br/>
eigentlichen Tests eingehen, müssen wir erst einige Konzepte einführen. <br/>


### Testplätze {#testplätze}

Hiermit ist nicht gemeint, ob in der Pruduktion 4 oder 8 Leute Geräte zusammenbauen. <br/>

Sondern die verschiedenen Orte, an denen wir Testen möchten: <br/>

-   nach der Produktion der Hauptplatine --- dies sollte schon beim Herstellungsort <br/>
    geschehen, um aufwändige Rückliefergen vorzubeugen. Zu diesem Zeitpunkt gibt es <br/>
    aber keine Front-Platine (Display, Fronttasten, Touch, Defroster). Daher dürfen <br/>
    Tests dafür hier nicht ablaufen <br/>
-   Endgerätefertigung nach Kundenwunsch: hier wird ein Mainboard mit der gewünschten <br/>
    Front zusammengeführt. Je nach Auftrag kann das 10", 12" oder 15" sein. Verschiedene <br/>
    LCD-Aufläsungen. Verschiedene Anzahl von Tasten auf der Front. Da diese Geräte hinterher <br/>
    an den Kunden gehen, gibt es auch Sichtprüfungen ("Hat die Lackierung einen Kratzer?") <br/>
-   Service: auch hier sollten Tests ausführbar, aber i.d.R. manuell. Auch dürfen diese Tests <br/>
    keinerlei Änderungen durchführen. Also nicht automatisch "Oh, das BIOS ist veraltet, <br/>
    ich flash da mal ein Neues drauf". Der Grund liegt darin, das manche Kunden die Geräte <br/>
    in EXAKT der abgenommenen Konfiguration haben wollen, einschließlich der BIOS-Version <br/>

Man kann nun jeden Test einzeln an einen oder mehrere Testorte (auch an alle) binden. <br/>


### Testarten {#testarten}

Naturgemäß gibt es mehrere Tests <br/>

-   automatische Tests: diese liebt der Leiter der Fertigung. Sie laufen <br/>
    vollautomatisch ab, oft in Sekundenbruchteilen. Sie sind daher (nahezu) <br/>
    kostenneutral. Nahezu, weil man für einige dieser Test vorher die passenden <br/>
    Teststecker einstecken muss. Beispiel: Prüfen der seriellen Schnittstelle. <br/>
    Automatische Tests werden einer nach den anderen ausgeführt. <br/>
-   manuelle Tests: hier geht es um Dinge, die man nicht automatisieren kann --- <br/>
    oder deren Automatisierung zwar an sich möglich ist, sich aber aufgrund der <br/>
    Stückzahlen nicht lohnt. Beispiel: obige "Hat das Gehäuse einen Kratzer?" <br/>
    Abfrage. Auch manuelle Tests werden einer nach den anderen ausgeführt. <br/>
-   optionale Tests: manchmal ist eine Hardware nur für machen Kunden verbaut, <br/>
    aber nicht generell. Also muss z.B. der CAN-Test nicht immer ausgeführt <br/>
    werden. Diese Tests müssen per Menü per Hand ausgewählt werden. <br/>

Man weist nun jeden Test eine Testart zu. Diese kann auch verschieden sein: <br/>
viele automatische Tests der Produktion sind optionale Tests im Service. <br/>


### Geräte {#geräte}

Bedingt durch die Hardware-Erkennung des zugrundeliegenden <br/>
"[ Combined-Linux: ein Image für viele Geräte ]({{< relref "combined-linux" >}})" läuft <br/>
der Teststick auf viele Gerätetypen und Varianten. Aber ein i2c-Test für den <br/>
DLT-V83 muss natürlich nach anderen Devices suchen als einer für den DLT-V72. <br/>

Man weist nun jeden Test eine oder mehrere Geräte zu. <br/>

Auch kann man einen Test an eine USB- oder PCI-ID binden. <br/>


### Aufbau der Tests {#aufbau-der-tests}

Jeder Test ist ein einzelnes File im "`tests/`" Verzeichnis, für sich abgeschlossen. Die <br/>
Komplexität der Tests ist i.d.R. gering, zwischen 10 und 330 Programmzeilen. Je nach dem, <br/>
was einfacher war, wurden sie in Bash oder Python geschrieben. <br/>

Jeder Test hat speziell formatierte Kommentare, die Testorte, Testarten und Geräte definieren. <br/>
Hier ein Beispiel für "`report_cpu_snr.sh`": <br/>

```sh
#!/bin/bash

# Test: auto everywhere G7I??C??

. lib.sh

head "CPU board serial number"

./amidelnx_26_32 /BS | grep Done || error "cannot get SNR"

ok "done"
```

Das ist ein automatischer Test, der an jedem Testort ausgeführt werden soll, <br/>
jedoch nur für die Geräteklasse G7I??C??. <br/>

Derselbe "`^# Test:`"-Marker würde auch in einem Python-Test verwendet werden. <br/>
Dort werden meist komplexere Dinge getestet, welche in Bash nicht so einfach zu <br/>
lösen sind. Hier ein Beispiel: <br/>

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

Jaaaa, hier wird noch Python 2.7 verwendet. Bei Projektstart war Python 3 noch <br/>
nicht soweit. <br/>


## Kommunikation mit Test-Fixture {#kommunikation-mit-test-fixture}

Am Produktionsplatz der Hauptplatine für den DLT-V83 gab es auch ein <br/>
Test-Fixture. Dieses hat mit dem Teststick über ein serielles Kabel <br/>
kommunuziert. Die Testsoftware dort hat dann bei mir z.B. "Mach mal ordentlich <br/>
CPU-Last" angefordert und dann z.B. den aufgenommenen Strom gemessen, während <br/>
mein Testprogramm die Coretemp währenddessen gemessen hat. <br/>


## Testreport abspeichern {#testreport-abspeichern}

Nachdem alle Tests durchgeführt gab, hat der Produktionsmitarbeiter "Finalize <br/>
Tests" ausgeführt. Damit wurde dann ein Testprotokoll per SMB oder FTP auf einem <br/>
Server im Produktionsnetz (vom Firmennetz getrennt!) gespeichert. <br/>

Dort waren natürlich alle Testergebisse, aber man konnte auch nachvollziehen <br/>
oder ein optionaler Test ausgeführt worden ist ... oder nicht. <br/>

Neben reinen Testergebnissen wurden dort auch viele Informationen abgespeichert, <br/>
beispielsweise die MAC-Adresse der Ethernet- und WIFI-Ports --- so haben wir <br/>
z.B. bemerkt, das wir einmal viele Mainboards mit identischen MAC-Adressen <br/>
geliefert bekamen. <br/>


## Dazugehörige Projekte {#dazugehörige-projekte}

Die folgenden Projekte sind mit dem "`hwtester`" verwandt, weil er entweder <br/>
darauf aufbaut, es nutzt oder das Projekt extrem ähnlich ist. <br/>

-   [ Combined-Linux: ein Image für viele Geräte ]({{< relref "combined-linux" >}}) <br/>
-   [ automatisch Images erstellen ]({{< relref "mkimage" >}}) <br/>
-   [ Dynamischer Flash-Schutz ]({{< relref "dynamischer-flashschutz" >}}) <br/>
-   TODO(Artikel schreiben) Hardware-Teststick für DLT-V73 <br/>

Die Projekte, die mit diesem Tool erstellte Images verwenden zähle ich jetzt mal <br/>
nicht auf :-)

