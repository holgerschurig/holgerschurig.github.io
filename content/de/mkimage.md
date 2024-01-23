+++
title = "Automatische Image-Erstellung"
author = ["Holger Schurig"]
date = 2024-01-17
tags = ["linux", "kernel", "systemd", "make", "debian", "dpkg", "eatmydata"]
categories = ["job"]
draft = false
+++

System um Linux-Images automatisch zu erstellen (einfacher und schneller als
OpenEmbedded, Puppet, Ansible etc).

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Projekt-Info](#projekt-info)
- [Anforderungen](#anforderungen)
- [Vorgehensweise](#vorgehensweise)
    - [debootstrap](#debootstrap)
        - [Erwähnenswert](#erwähnenswert)
        - [Ergebnis](#ergebnis)
    - [Kernel-Erstellung](#kernel-erstellung)
        - [Kernel-Source](#kernel-source)
        - [Kernel-Konfiguration](#kernel-konfiguration)
        - [externe Treiber](#externe-treiber)
        - [Erwähnenswert](#erwähnenswert)
    - [systemd](#systemd)
    - [wpasupplicant](#wpasupplicant)
    - [Pakete, Konfigurationsdateien](#pakete-konfigurationsdateien)
        - [Erwähnenswert](#erwähnenswert)
        - [Ergebnis](#ergebnis)
- [Verwandte Projekte](#verwandte-projekte)

</div>
<!--endtoc-->

<div class="job">

In Beiträgen der Kategorie [Job](/categories/job/) trage ich Projekte zusammen, die ich im Rahmen
meiner beruflichen Karriere federführend durchgeführt habe. Ich gehe dabei mit
Absicht nicht allzusehr auf Details an: die Interessen meiner Arbeitgeber sollen
ja nicht berührt werden.

</div>


## Projekt-Info {#projekt-info}

Idee &amp; Umsetzung: ich

Nutzung: 2012 bis heute

Implementatierung: Make, Bash, Python

Effizienzgewinn:

-   jeder Änderung via "git log" / "git blame" verifizierbar
-   Directory-basierte Images lassen sich per "`rsync`" in Sekundenschnelle auf
    Geräte übertragen und testen
-   extrem schneller Image build (600 MB Image in 23 Sekunden) bedeutet einen
    schnellen Turnaround bedeutet das neue Features schneller getestet werden können


## Anforderungen {#anforderungen}

-   das Ergebnis sollte **eine Standard-Distribution** sein (hier: Debian), nicht etwas
    spezielles wie beispielsweise bei TODO(Artikel schreiben) "OpenEmbedded"
-   die Image-Erstellung sollte ausgesprochen **schnell** gehen
-   Images sollten **reproduzierbar** sein
-   **geringe Komplexität** (also deutlich einfach wie weiland
    TODO(Artikel schreiben) "OpenEmbedded"
-   **keine Client/Server-Architektur**: das Image soll in einem Verzeichnis gebaut werden
-   **keine Artefakte im Image** vom eigentlichen Build-Prozesses --- Kunden
    mögen es nicht, wenn irgendwelche Daemons offene Ports haben (außer vielleich SSH).


## Vorgehensweise {#vorgehensweise}

{{< figure src="mkimage.png" >}}


### debootstrap<span class="org-target" id="org-target--debootstrap"></span> {#debootstrap}

[Debootstrap](https://wiki.debian.org/de/Debootstrap) erzeugt ein  Debian-Basissystem in einem Unterverzeichnis. Es braucht
keine Installations-CD, sondern lediglich Zugriff auf die Debian-Repositories.

So ein Basissystem ist selbst nicht bootbar --- man kann es aber schon z.B. in
Docker nutzen. Ich nutze es, um aus diesem minimalen Basis-System dann das
[ Combined-Linux ]({{< relref "" >}}) zu erstellen.

```text
~/d/mkimage$ time make debootstrap
sudo make debootstrap
rm -rf image.debootstrap.bookworm.amd64
mkdir -p downloads/debootstrap.bookworm.amd64
mkdir -p downloads/apt.bookworm.amd64
eatmydata -- debootstrap \
    --arch amd64 \
    --variant=minbase \
    --no-check-gpg \
    --cache-dir=downloads/apt.bookworm.amd64 \
    --exclude [weggelassen]... \
    --include apt-utils,procps,xz-utils \
	bookworm image.debootstrap.bookworm.amd64 https://deb.debian.org/debian/
...
touch --no-create image.debootstrap.bookworm.amd64/etc/debian_version

real    0m27.615s
user    0m0.034s
sys     0m0.036s
```


#### Erwähnenswert {#erwähnenswert}

-   [eatmydata](https://www.flamingspork.com/projects/libeatmydata/) reduziert das excessive "`fsync()`" von "`dpkg`". Das Filesystem
    syncen ist gänzlich unnötig, wenn man sich das
-   ein Cache-Directory "`downloads/apt.bookworm.amd64`" schont die Debian-Server und erhöht die
    Geschwindigkeit --- dies ist einer der Bereich, die Docker bis heute nicht gut gelöst hat.
-   28 Sekunden ist ein durchaus netter Wert


#### Ergebnis {#ergebnis}

Anschließend hat man eine Minimales Debian in einem Directory, welches man für

-   [ Combined-Linux ]({{< relref "" >}})
-   TODO(Artikel schreiben) Linux Restore Stick
-   TODO(Artikel schreiben) Teststick
-   TODO(Artikel schreiben) Teststick UEFI

einsetzen kann.

```text
~/d/mkimage$ ls image.debootstrap.bookworm.amd64/
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
~/d/mkimage$ sudo du -hs image.debootstrap.bookworm.amd64/
182M	image.debootstrap.bookworm.amd64/
```


### Kernel-Erstellung {#kernel-erstellung}

Auch die Erstellung des Kernels ist automatisiert. Möchte man diesen Schritt einzeln ausführen,
kann man jederzeit z.B.

```text
~/d/mkimage$ make cleankernel
...
~/d/mkimage$ time make -j8 compkernel
...
real	2m58.199s
user	18m18.395s
sys	2m40.577s
```

ausführen. Das ganze dauert also nur 3 Minuten.


#### Kernel-Source {#kernel-source}

Auf den Geräten läuft ein selbst-kompilierter Kernel, basierend auf
<https://kernel.org>. Das liegt daran, das der Standard-Debian-Kernel eher für
Desktop- und Serverumgebungen gemacht ist, weniger für Embedded.

Also nehme ich jeweils einen aktuellen, stabilen Upstream-Kernel von [kernel.org](https://kernel.org),
füge AUFS für den [ dynamischen Flash-Schutz ]({{< relref "dynamischer-flashschutz" >}})
hinzu. Anschließend werden noch jede Menge Patches mit Hilfe von [quilt](https://git.savannah.nongnu.org/cgit/quilt.git/tree/doc/README.in)
angewandt. Diesen haben oft diese Zwecke:

-   Unterdrücken von harmlosen Kernel-Warnungen, die aber den Kunden beim Booten des
    Images verunsichern würden
-   TODO Optimierungen des Linux mac80211 Layers und diverser WLAN-Treiber (z.B. Atheros)
    zum besseren Roaming
-   Geschwindigkeitsoptimierungen für ein schnelleres Booten / Filesystem

Die Kernel-Sourcen werden direkt von [kernel.org](https://kernel.org) heruntergeladen und in
"`downloads/`" gecacht.


#### Kernel-Konfiguration {#kernel-konfiguration}

Neben den Patches gibt es auch noch in "`*.kconfig`" Files eine
Kernelkonfiguration. Die wichtigste ist natürlich "`default.kconfig`". Sie macht
nur Dinge an, die wir brauchen. Ein Beispiel: Debian hat "Hot CPU Swap" an --
aber das wird bei Industrie-Geräten nie der Fall sein. Man müßte das Gerät
komplett zerlegen, um an die CPU zu kommen.

Neben der Default-Konfiguration gibt es noch für jedes unterstützte Gerät eine
"`device-XXXX.kconfig`" Datei, welches Treiber für dieses spezifische Gerät
aktiviert. Ein Beispiel:

```text
#00:02.0 VGA compatible controller [0300]: Intel Corporation Atom Processor Z36xxx/Z37xxx Series Graphics & Display [8086:0f31] (rev 11)
CONFIG_DRM_I915=m

#00:14.0 USB controller [0c03]: Intel Corporation Atom Processor Z36xxx/Z37xxx Series USB xHCI [8086:0f35] (rev 11)
CONFIG_USB_XHCI_HCD=y
```


#### externe Treiber {#externe-treiber}

Es gibt (oder gab) noch diverse externen Kernel-Module, beispielsweise zur Hardware-Erkennung,
BIOS-Updates, Penmount-Treiber, diverse externe USB-Geräte.


#### Erwähnenswert {#erwähnenswert}

-   die schnelle Kompilationszeit kommt daher, das viele Kernel-Subsysteme erst gar nicht
    kompiliert werden. Warum sollte ein Image für die Industrie Treiber für Graphics-Tablets
    oder DVB-S (Satelittenfernsehen) habe?


### systemd {#systemd}

Wir nutzen nicht den systemd des Debian-Projektes, denn dieser ist eher für
Rechenzentren gedacht. Er enthält viele Dinge, die man auf einem Embedded-Device
eher nicht braucht. Beispiele: quotacheck, importd, timedated, localed ...

Außerdem werden viel mehr .deb Pakete erzeugt, insgesamt 54. Installiert werden davon
aber nur wenige. Die meisten werden nur vorgehalten, sollte ein Kunde das jemals brauchen.
Beispiele: rfkill, cgls, cgtop, kernelinstall, journal-gatwayd, journal-remote ...


### wpasupplicant {#wpasupplicant}

Wir compilieren auch unseren eigenen WPA-Supplicant, um das Roamingverhalten zu verbessern.
Sie dazu den Artikel

-   TODO(Artikel schreiben) Schnelles WLAN-Roaming


### Pakete, Konfigurationsdateien {#pakete-konfigurationsdateien}

Nun ist es Zeit, das eigentliche Image zu erstellen. Dies geschieht mit diesen Komponenten:

-   "`bin/run`" enthält viele Shell-Funktionen und kann Shell-Scriptlets sourcen
-   "`base/*`" enthält viele dieser Shell-Scriptlets, beispielsweise "`base/kernel`"
    oder "`base/tool-rsync`" die jeweils eine Sache installieren bzw. konfigurieren
-   "`conf/base-image.conf`" definiert, welche von den "`base/*`" Scripten genutzt werden
    sollen
-   "`conf/base-config.imgconf`" definiert, welches Debian wir verwenden (also beispielsweise
    "bookworm" für die Architektur "amd64")

Lassen wir das doch einfach mal ablaufen:

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--b14937 }
$ time make image
make checkconfig
make[1]: Entering directory '/home/holger/d/mkimage'
make[1]: Leaving directory '/home/holger/d/mkimage'
sudo make image CUST="" IMAGE=image
umount -f image/proc 2>/dev/null
make: [Makefile.image:36: image] Error 32 (ignored)
umount -f image/sys 2>/dev/null
make: [Makefile.image:37: image] Error 32 (ignored)
umount -f image/dev 2>/dev/null
make: [Makefile.image:38: image] Error 32 (ignored)
rm -rf image
bin/run
Info : using conf/image.imgconf

running base/image
running base/eatmydata
running base/firmware-radeon
running base/firmware-realtek
running base/kernel
running base/systemd
...
running base/wireless
-> get ftp.de.debian.org/debian/pool/main/libn/libnl3/libnl-genl-3-200_3.7.0-0.2+b1_amd64.deb
-> get ftp.de.debian.org/debian/pool/main/libn/libnl3/libnl-3-200_3.7.0-0.2+b1_amd64.deb
-> get ftp.de.debian.org/debian/pool/main/libn/libnl3/libnl-route-3-200_3.7.0-0.2+b1_amd64.deb
-> get ftp.de.debian.org/debian/pool/main/p/pcsc-lite/libpcsclite1_1.9.9-2_amd64.deb
running base/lib-x11
...
running base/rm
finished !!!

real    0m23.599s
user    0m0.090s
sys     0m0.019s
```

-   in Zeile [2](#org-coderef--b14937-2) prüfen wir, ob z.B. in den in C++/Qt geschrieben
    config-Tool noch Debugausgaben sind
-   Zeile [5](#org-coderef--b14937-5) erkennt, das wir noch ein normaler User sind. Es wird dann
    automatisch nach Root gewechselt.
-   Zeile [6](#org-coderef--b14937-6) versucht, Mounts zu löschen. Diese können entstehen, wenn man
    einen vorherigen "`make image`" mit Ctrl-C abbricht -- dies lässt sich in
    Makefiles nicht abfangen (die Bash könnte es).
-   Zeile [12](#org-coderef--b14937-12) bedeutet, das wir mit ein vorheriges "`image/`" Directory
    löschen. Dorthinein wird unser Image generiert. Das ist ähnlich wie oben bei
    Debootstrap, das ein "`image.debootstrap.bookworm.amd/`" erstellt hatte.
-   Zeile [13](#org-coderef--b14937-13) schließlich führt das "`bin/run`" Programm aus, welches rekursive
    Scriptlets in "`base/*`" ausführen kann
-   das erste Scriptlet wird in Zeile [16](#org-coderef--b14937-16) ausgeführt. Es legt ein frisches
    "`image/`" Directory an und kopiert erstmal das Debootstrap-Image dort hinein.
-   danach werden viele weitere Scriptslets ausgeführt auf die ich nicht weiter
    eingehe
-   die meisten Schritte hatten schon die nötigen Debian-Pakete im .deb Cache
    ("`downloads/deb.bookworm.amd64/`". Aber in Zeile [24](#org-coderef--b14937-24) kann man sehen, das
    noch fehlende Debian-Pakete automatisch heruntergeladen werden. Das erledigt
    ein kleines Python-Script, "`bin/get_deb.py`".
-   am Schluss wird es in Zeile [30](#org-coderef--b14937-30) wieder etwas besonders: da wir Images für
    Embedded Devices erstellen, können wir viele Dinge löschen. Beispiel: es ist sowas
    kein "`man`" Binary installiert. Also kann man auch einfach alle Manpages löschen.


#### Erwähnenswert {#erwähnenswert}

Wer jemals ein Docker-Image auf Debian-Basis erstellt hat, wird sich evtl die
Augen reiben: wie kann man ein Image in gerade mal 23 Sekunden bauen? Allein die
Docker-Zeile "apt-get update; apt-get install foo bar baz; apt-get clean"
braucht wesentlich länger?

Der Trick ist hier ist:

-   einerseite die Installation von "`eatmydata`" ins Image hinein (siehe Zeile
    [17](#org-coderef--b14937-17) oben. Es wird dann beim Installieren von "`.deb`"-Paketen kein
    "`fsync()`" or "`open(...,O_SYNC)`" ausgeführt.
-   manuelles Dependency-Resolving. Hier in Beispiel: um BlueZ (den Linux-Bluetooth-Daemon)
    zu installieren, braucht man vorher einige Libraries. Statt "`apt`" das herausfinden zu lassen,
    finde ich es einmalig heraus und fordere die explizit. Die Datei "`base/bluez`" sieht dann z.B.
    so aus:

<!--listend-->

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--2afbaf }
need base/user
need base/systemd
need base/lib-glib

install_debian_deb bluez
install_debian_deb libbluetooth3
install_debian_deb libdw1
install_debian_deb libasound2
install_debian_deb libasound2-data
install_debian_deb libreadline8
install_debian_deb readline-common

do_run()
{
    mkdir -p ${IMAGE_DIR}/etc/systemd/system/bluetooth.service.d/
    copy_file less-services.conf etc/systemd/system/bluetooth.service.d/

    ...
    in_image adduser --quiet dlog bluetooth >/dev/null
}
```

Das bedeutet im einzelnen:

-   bevor "`base/bluez`" ausgeführt werden kann, muss (Zeile )) ein Standard-User
    angelegt werden. Das liegt daran, das wir diesen User mit "`addgroup`" in die Gruppe
    "bluetooth=" aufnehmen wollen (Zeile [19](#org-coderef--2afbaf-19)).
-   dann brauchen wir noch systemd vorher im Image, da wir ein Drop-In Konfigurationsfile
    reintun, welches Teile des Debian-BlueZ-Unit überschriebt (Zeile [16](#org-coderef--2afbaf-16)).
-   BlueZ braucht wie viele andere Programm die glib. Statt also alle .deb unten
    anzuführen, die glib installieren, habe ich das in ein eigenes
    "`base/lib-glib`" ausgelagert (Zeile [3](#org-coderef--2afbaf-3)).
-   "`need`" ist übrigens eine Shell-Funktion, definiert in "`bin/run`". Dasselbe gilt
    für "`install_debian_deb`" und "`in_image`".
-   nun wird BlueZ selbst in Zeile [5](#org-coderef--2afbaf-5) und alle benötigten Libraries installiert
    (Zeilen [6](#org-coderef--2afbaf-6) bis [11](#org-coderef--2afbaf-11)).
-   Wenn alle Debian-Pakete installiert sind, wird die Funktion "`do_run`" in
    Zeile [13](#org-coderef--2afbaf-13) aufgerufen. Sie kann beliebige Programme aufrufen, einmal
    außerhalb des neu erstellten Images, aber auch innerhalb mit Hilfe von
    "`in_image`". Außerdem sind diverse Environment-Variablen wie "`$RUN_HOME`",
    "`$IMAGE_DIR`" und "`$DATA_DIR`" definiert.


#### Ergebnis {#ergebnis}

```text
~/d/mkimage$ ls image
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
~/d/mkimage$ sudo du -hs image
639M	image
```

Diese Image kann nun mit "`cd image; tar cvzf ../combined-linux.tar.xz .`" eingepackt werden. Dieses
File würde man dann auf einen TODO(Artikel schreiben) "Linux Restore Stick" kopieren und damit
Geräte initialisieren.

Man kann es auch mir "`rsync`" direkt per Ethernet oder WLAN auf ein Gerät
syncen --- das ist erheblich schneller: nach wenigen Sekunden ist das neue
erstellte Image testbar.


## Verwandte Projekte {#verwandte-projekte}

Die folgenden Projekte verwenden mkimage direkt oder ähnlich:

-   [ Combined-Linux: ein Image für viele Geräte ]({{< relref "combined-linux" >}})
-   TODO(Artikel schreiben) Linux-Image auf Basis von i.MX&amp; RISC Prozessor für den Tagebau
-   TODO(Artikel schreiben) Linux Restore Stick
-   [ Hardware-Teststick für DLT-V83/DLT-V72 ]({{< relref "hwtester" >}})
-   TODO(Artikel schreiben) Hardware-Teststick für DLT-V73
