+++
title = "Linux-Image auf Basis von i.MX& RISC Prozessor für den Tagebau"
author = ["Holger Schurig"]
date = 2024-01-22
tags = ["arm", "can", "embedded", "imx6", "linux", "openembedded", "qemu-user-status"]
categories = ["job"]
draft = false
+++

Wie man sich das zeitaufwändige Cross-Compilieren mit OpenEmbedded spart.

Oder: Implementierung eines Linux-Images auf eine RISC-Platform für einen sehr
rauhen Anwendungsfall.

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Projekt-Info](#projekt-info)
- [Projekt-Background](#projekt-background)
- [Komponentenauswahl](#komponentenauswahl)
- [Board-Bringup](#board-bringup)
- [Images](#images)
    - [Basis-Image: multistrap statt Debootstrap](#basis-image-multistrap-statt-debootstrap)
    - [Wie man (nicht) cross-compiliert](#wie-man--nicht--cross-compiliert)
    - [Kunden-Images](#kunden-images)
- [Linux-Kernel](#linux-kernel)
- [Kleinere Tools](#kleinere-tools)
- [Projekt-Tracking](#projekt-tracking)
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

Idee: Kundenanforderung

Umsetzung: Barebox, Linux und Image: ich

Nutzung: US-amerikanischer Minenausrüster

Implementatierung: Make, Bash, Python, Meson, C, C++, Qt, Git, Emacs, qemu-user-static


## Projekt-Background {#projekt-background}

Ein US-amerikanischer Ausrüster von Minen (in Deutschland z.B. bei Kali &amp; Salz)
hat spezielle Terminals von uns genutzt --- diese Terminals besonders Robust und halten
auch starken und dauerhaften Erschütterungen stand.

{{< figure src="./ahs.jpg" >}}

Auf dem Foto sieht der Truck ganz klein aus --- tatsächlich ist aber ein Rad
schon höher als die dicksten SUVs. In diesem Video wird das Projekt vorgestellt:
<https://youtu.be/6Nw7q0t2A9o>. Wer aufpasst, kann zum Zeitstempel 0.37 einmal
kurz das Device sehen.

Der Kunde hatte auf ein Vorgängergerät WinCE eingesetzt --- aber aufgrund massiver
Fehler in Windows CE, die Microsoft nie behob, war er mit der Software sehr unzufrieden.

Nun sollte auf Linux umgestellt werden, wobei ich den Kunden half. Allerdings
wurde auch eine neue Gerätegeneration entwickelt, um den geänderten
Anforderungen entsprechen zu können.


## Komponentenauswahl {#komponentenauswahl}

Viele Hersteller von ICs behaupten "Wir haben Linux-Support". Doch vor allem bei
asiatischen Lieferanten haben die dann einmalig vor 4 Jahren von irgendwem einen
Treiber entwickeln lassen, der dann auch nur mit einem seit 4 Jahren veralteten
Linux-Kernel funktioniert.

Deswegen habe ich schon beim Projektdesign die Hardware-Entwicklung beraten,
welche Chips oder Hersteller (Marvell und Broadcomm rücken kaum mit Infos raus!)
man meiden sollte.


## Board-Bringup {#board-bringup}

Nachdem die ersten Prototypen PCBs da waren, ging es um den Board-Bringup.

Zunächst habe ich mit einem Freescale / NXP - Tool die Timing-Parameter des DRAM
herausgefunden. Der leitende Elektronikingeneur tat dasselbe --- und wir hatten
komplett verschiedene Werte, die jeweils beim anderen nicht funktionierten. Dies
stellte sich als Fertigungsprobleme heraus, die dann behoben werden.

Als Bootloader hatte ich diesmal nicht u-boot, sondern [Barebox](https://www.barebox.org) genommen. Der war
viel moderner programmiert, ähnlich wie der Linux-Kernel. Er hat sogar wie der
Linux-Kernel ein "Kconfig" System, das damals bei u-boot noch nicht existierte.
Auch hat er denselben Device-Tree genutzt, den ich dann auch für den
Linux-Kernel genommen habe.


## Images {#images}

Das Image wurde mit einem ähnlichen System erstellt wie im Artikel
[ Combined-Linux: ein Image für viele Geräte ]({{< relref "combined-linux" >}})
beschrieben. Also **nicht** mit [ OpenEmbedded ]({{< relref "openembedded" >}}). Das
führte zu einer erheblichen Zeitersparnis.

Das lag daran, das es keinerlei Cross-Compilation gab.

Doch wie geht das, wenn der Entwicklerrechner "i386" als Architektur hat, das
Zielsystem aber "armhf"?

Ganz einfach: mit der Hilfe von QEMU. Viele Leute kennen dieses Tool, normal
simuliert es komplette Rechner, also CPU, RAM, Flash, Devices. Aber es gibt auch
[qemu-user-static](https://github.com/multiarch/qemu-user-static). Dieses simuliert nur die CPU. Keinerlei Hardware ... sämtliche
Aufrufe von Linux-Kernel-Funktionen wie "`open()`", "`read()`" etc werden
stattdessen einfach an den Host-Kernel (also mein i386/amd64 -Kernel) übergeben.
Der führt das dann ganz normal aus.

Damit das klappt, nutzt man "`binfmt-misc`". Das ist ein Subsystem des Kernels.
Wenn ein Executable ausgeführt wird, schaut er sich die ersten Bytes an,
vergleicht diese mit ihm vorher bekannt gemachten Signaturen und startet dann
das Binary halt nicht direkt, sondern über ein Hilfsprogramm.


### Basis-Image: multistrap statt Debootstrap {#basis-image-multistrap-statt-debootstrap}

... oder besser: multistrap. Das war damals besser für fremde Architekturen
geeignet als debootstrap. Debootstrap selbst habe ich ja bereits
[ hier ]({{< relref "mkimage#debootstrap" >}}) beschrieben.

Also geht's hier mal um Multistap.

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--f87743 }
image.base:
    @test `id -u` = 0 || { echo "\n---> You need to run this as root\n"; exit 1; }
    @# Make ARM binaries runnable with the help of qemu-user-static
    update-binfmts --enable
    @# create new base image
    rm -rf image.base
    multistrap --dir image.base -f conf/multistrap.conf
    @# Create device nodes
    bin/device-table.pl -f $(PWD)/conf/multistrap.devices -d image.base
    @# Somehow the dash postinst script doesnt run because of debconf trouble
    rm -f image.base/var/lib/dpkg/info/dash.postinst
    echo /bin/dash >>image.base/etc/shell
    @# We dont want to have services run automatically
    ln -sf /bin/true image.base/usr/sbin/invoke-rc.d
    @# This makes the armhf dpkg binary be executable in the following chroot command
    cp /usr/bin/qemu-arm-static image.base/usr/bin
    @# Mount needed system directory
    mount -o bind /proc image.base/proc
    mount -o bind /sys image.base/sys
    mount -o bind /dev/pts image.base/dev/pts
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        LC_ALL=C LANGUAGE=C LANG=C \
        chroot image.base dpkg --configure -a
    umount image.base/proc
    umount image.base/sys
    umount image.base/dev/pts
```

Die Zeilen [4](#org-coderef--f87743-4) und [16](#org-coderef--f87743-16) sind hier die "Secret Sauce". Zunächst müssen wir
ja dafür sorgen, das der Kernel "armhf" Binaries überhaupt ausführen kann --- bei heutigen
Debian-Versionen wird "`update-binfmts`" übrigens schon beim Booten ausgeführt.

Dann müssen wir natürlich noch das "`qemu-arm-static`" Binary (ein i386 btw
amd64) Binary in das armhf-Image-Directory kopieren. Sonst wäre es ja nach dem
"`chroot`" nicht erreichbar. Es ist, wie der Name schon andeutet, statisch
kompiliert. Es lädt also keinerlei Libraries aus "`/lib`" bzw "`/usr/lib`"
nach... denn im "`chroot`" wären die ja von der falschen Architektur und könnten
sowieso nicht geladen werden.

Das besondere an "`multistrap`" war, das es alle Debian-Pakete zwar ausgepackt
hat, dann aber die viele Scripte "`image.base/var/lib/dpkg/info/*.postinst`"
**nicht** ausgeführt hat. Das hätte ja nicht geschehen können, da "`multistrap`"
ja selbst noch unter i386/amd64 lief. Die Scripte aber rufen oft Binaries wie
z.B. "`addgroup`" auf. Und in "`image.base/`" sind diese halt von der
Architektur "`armhf`".

Die installierten Pakete sind also sozusagen noch nicht konfiguriert.

Deswegen wird in Zeile [21](#org-coderef--f87743-21) das Konfigurieren nachgeholt: "`dpkg --configure
-a`" wird mit Hilfe von "`chroot`" innerhalb von "`image.base/`" aufgerufen.
Dadurch werden alle "`*.post`" Scripte aufgerufen. Mittlerweile ist aber
"`qemu-user-static`" im Image verfügbar, und die Scripte können nach Herzenslust
"armhf" Binaries nutzen.


### Wie man (nicht) cross-compiliert {#wie-man--nicht--cross-compiliert}

Will (oder muss) man dann aber doch compilieren, geht auch das sehr einfach.

Ich kann das Basis-Image von "`image.base/`" nach "`image.dev`" kopieren und
dann dort alles installieren, was ich so zum Compilieren brauche: gcc, make,
cmake, meson, ninja, diverse \*-dev Libraries etc etc.

Und wenn ich dann mit "`chroot`" in dieses "`image.dev`" wechsle, kann ich
dort "armhf" Binaries direkt compilieren --- obwohl mein Host eigentlich
"i386" oder "amd64" Architektur hat.

Das ist ein wenig langsamer als native zu compilieren. Denn der
"`qemu-user-static`" emuliert schließlich eine CPU, dadurch wird der komplette
Compilationsprozess ja emuliert.

Aber es ist immer noch schneller als mit OpenEmbedded, da man ja nicht erst ein
Staging-Directory mir "armhf"-Libraries bevölkern muss.

Hier ist ein Beispiel, wie ich "`x11vnc`" (nicht) cross-compiliert habe:

```text
VNC_VER=0.9.14
VNC_TAR=x11vnc-$(VNC_VER)-dev.tar.gz
PACKAGES += downloads/$(VNC_TAR)

downloads/$(VNC_TAR):
    wget -q -c -P downloads http://x11vnc.sourceforge.net/dev/$(VNC_TAR)

image.dev/x11vnc-$(VNC_VER)/configure: downloads/$(VNC_TAR)
    cd image.dev; tar xaf ../$<
    ln -sf ../../patches-x11vnc image.dev/x11vnc-$(VNC_VER)/patches
    cd image.dev/x11vnc-$(VNC_VER); quilt push -a
    touch --no-create $@

image.dev/x11vnc-$(VNC_VER)/Makefile: image.dev/x11vnc-$(VNC_VER)/configure
    chroot image.dev dash -c "cd x11vnc-$(VNC_VER); ./configure \
        --prefix=/usr \
        --without-ipv6 \
        --without-v4l \
        --without-fbdev \
        --without-uinput \
        --without-macosx-native \
        --without-crypt \
        --without-crypto \
        --without-ssl \
        --without-gnutls \
        --without-client-tls"

compvnc image.dev/x11vnc-$(VNC_VER)/x11vnc/x11vnc: image.dev/x11vnc-$(VNC_VER)/Makefile
    chroot image.dev make -j4 -C x11vnc-$(VNC_VER)
    chroot image.dev strip x11vnc-$(VNC_VER)/x11vnc/x11vnc

cleanvnc:
    rm -rf image.dev/x11vnc-$(VNC_VER)
```

Mit obigen Makefile-Snippets reicht ein "`make compvnc`" aus, das

-   eine bestimme Version der x11vnc-Sourcen heruntergeladen werden (falls sie noch nicht da sind)
-   dieser Source wird ausgepackt
-   mit lokalen Patches versehen (die ich also im eigenen GIT habe)
-   mit meinen Konfigurationsoptionen konfiguriert
-   und kompiliert

Anschließend hat man in "`image.dev/x11vnc/x11vnc`" das Binarie, das ich dann z.B. ins Kundenimage
kopieren kann.

Ich kann aber in "`image.dev`" auch reguläre Debian-Pakete erzeugen, aber das
sprengt diesen Post.


### Kunden-Images {#kunden-images}

Mit dem nur leicht abgewandelten im Post [ Automatische Image-Erstellung ]({{< relref "mkimage" >}}) wurden
dann im Laufe der Jahre drei Kunden-Images erstellt:

-   eines mit Java (der Kunde hatte seine Anwendung in Java geschrieben)
-   eines mit Mono (eine andere Anwendung wurde in C# geschrieben)
-   eines komplett ohne X11 und GUI (für eine Version des Gerätes ohne Display)

Je nachdem, welches Image ich (reproduzierbar) erstellt habe, dauerte dies 3 bis
6 Minuten.


## Linux-Kernel {#linux-kernel}

Auch hier wurde ein Linux-Kernel "dem Gerät auf den Leib geschneidert", also vom Source compiliert.

Netterweise hat sowohl Freescale als auch NXP (kaufen Freescale auf) mit der
Kernel-Community mitgearbeitet. Zwar hatten sie ihren eigenen Vendor-Kernel, wie
üblich hoffnungslos veraltet. Aber: sie brachten jeden Treiber "upstream" in den
offiziellen Linux-Kernel. Und dort haben dann die Subsysten-Maintainer immer ein Auge drauf
geworfen und teils drastische Verbesserungen erreicht.

Ich entschied mich also, einfach einen Kernel von <https://kernel.org> zu
verwenden: alle vom Kunden i.mX6 Subsystem wurden von ihm unterstützt.

Eine Besonderheit gab es aber bei CAN-Bus: hier hatte der Kunde hohe Anforderungen. Und
der CAN-Treiber vom offiziellen Linux-Kernel fiel durch. Der CAN-Treiber des Vendor-Kernels
(der ziemlich anders aussah) ... fiel auch durch. Hier habe ich mich dann in den Treiber
eingefuchst und habe dann einen Patch gemacht, der die sog. "Mailboxes" verwendet.

Nachdem der Kunde das getestet und für gut befunden hatte ... hat der
Linux-CAN-Maintainer einen ähnliche Änderung im offiziellen Linux-Kernel
eingebracht. Die haben wir dann übernommen --- was im Upstream-Kernel ist, wird
ja mit jeder Kernel-Version gepflegt. Was man "out-of-tree" hat, unterliegt
hingegen immer dem "Bitrot". Man ist damit nie so zukunftssicher.


## Kleinere Tools {#kleinere-tools}

-   uccomm (von µC-Communication): sprach mit den Microcontroller auf der
    Hauptplatine, um z.B. das Ein/Ausschaltverhalten zu steuern oder die Seriennummer
    auszulesen
-   Tool zum Einstellen des Hardware-Watchdog
-   Tool zur Device-Discovery (eine proprietäre Kundenlösung, kein mDNS oder SSDP)
-   ubloxcomm: von u-Blox gibt es tolle Einstellungsprogramme für ihre Chips ...
    leider damals nur für Windows. Also habe ich ein Tool geschrieben, welches das
    von der Kommandozeile machen konnte, da ich nichts vergleichbares gefunden in
    der Open-Source-Community gefunden hatte. Die Besonderheit war, das ich
    basierend auf eine Konfigurationsdatei beliebige Kommandos senden konnte ---
    auch für diesen Chip [undokumentierte](https://wiki.openstreetmap.org/wiki/U-blox_raw_format), die er aber anstandslos ausführte.
    Dieser Auszug aus der Konfigurationsdatei ermöglicht die Kommandos "`ubloxcomm
        sbas_on`", "`ubloxcomm sbas_off`" und "`ubloxcomm sbas_poll`":

<!--listend-->

```text
# Page 133: SBAS Configuration
#
#          CFG-SBAS
#          |    mode: bit 0 (mode) no longer supported, use CFG-GNSS. Bit 1 (use testbed) is ok
#          |    |  usage: use SBAS GEOs as ranging source, differential corrections, integrity informat
#          |    |  |  maxSBAS: no longer supported, use field in CFG-GNSS
#          |    |  |  |  scanmode2, scanmode1: if all are zero then search for all SBAS PRNs
sbas_on:   0616 01 07 03 00 00000000
sbas_off:  0616 00 00 03 00 00000000
sbas_poll: 0616
```

Die Zeilen konntena auch mehrfach auftauchen. Um z.B. den NMEA-Output via
"`ubloxcomm nmea_off`" abzustellen, hat die Konfigurationsdatei dies vorgesehen:

```text
# Page 107: Set Message Rate (for current port)
#
#              CFG-MSG
#              |    msgClass
#              |    |  msgId
#              |    |  |  rate for serial port
#              |    |  |  |  rate for other ports
nmea_off:      0601 f0 0a 00 00000000  # Datum Reference
nmea_off:      0601 f0 09 00 00000000  # GNSS Satellite Fault Detection
nmea_off:      0601 f0 00 00 00000000  # Global positioning system fix data
nmea_off:      0601 f0 01 00 00000000  # Latitude and longitude
nmea_off:      0601 f0 0d 00 00000000  # GNSS fix data
nmea_off:      0601 f0 06 00 00000000  # GNSS Range Residuals
nmea_off:      0601 f0 02 00 00000000  # Active Satellites
nmea_off:      0601 f0 07 00 00000000  # GNSS Pseudo Range Error Statistics
nmea_off:      0601 f0 03 00 00000000  # Satellites in view
nmea_off:      0601 f0 04 00 00000000  # Recommended Minimum data
nmea_off:      0601 f0 0f 00 00000000  # Dual ground/water distance
nmea_off:      0601 f0 05 00 00000000  # Course over ground and Ground speed
nmea_off:      0601 f0 08 00 00000000  # Time and Date
nmea_off:      0601 f1 00 00 00000000  # Lat/Long Position Data
nmea_off:      0601 f1 03 00 00000000  # Satellite Status
nmea_off:      0601 f1 04 00 00000000  # Time of Day and Clock Information
```

Man kann aus diesen Auszügen auch sehe, das ich normalerweise immer gut
dokumentiere. Im Header der Datei steht exakt der Name und die Version des PDF,
auf die sich die Seitennummern beziehen.


## Projekt-Tracking {#projekt-tracking}

Es gab eine umfangreiche "Requirement Spec" vom Kunden, die sich allerdings
recht häufig geändert hat. Der Grund war, das dem Kunden Linux neu war. Dinge
wie "Priviledge Separation" waren ihm beispielsweise unbekannt. Wenn ich eine
neue Spec bekam, habe ich das Word-Dokument immer mit der vorherigen Version
verglichen, die Änderungen festgestellt --- diese Kunde hat die
Revisionshistorie nur unzureichend geführt ---. Und dann habe ich manchmal
gedacht "Also, so wie das gewünscht wird ist das nicht Best Practice".

In den wöchentlichen Telcos, oder manchmal zwischendurch per E-Mail, habe ich dann
Änderungesvorschläge gemacht und die Gründe erläutert. Nahezu immer wurde dies
dann berücksichtigt.

Um diese sich ändernden Anforderungen zu tracken habe ich das Kunden-Requirement
in eine eigene Emacs [org-mode](https://orgmode.org/) Datei überführt.

Ich habe auch eigene Sub-Punkte mit hineingenommen --- dem Kunden war es
beispielsweise egal, ob i2c im Bootloader geht oder nicht. Aber mir nicht, da
ich schon im Bootloader auf diverse i2c-Geräte zugreifen wollte. Also habe ich
dies dann mit einem eigenen TODO-Punkt versehen.

Org-mode kann man sich wie den Source eines Wiki vorstellen --- man kann es also,
da es Text ist (im Gegensatz zu einer Word-Datei) mit in "`git`" aufnehmen. Im Editor
sieht das dann ungefähr so aus:

{{< figure src="./org-mode.png" >}}

(Dies ist übrigens ein Auszug aus den Anforderungen des Bootloaders. Beispielsweise
sollte er beim Booten piepsen, also mußte er den "Beeper" unterstützen).

Ich habe das dann aber dem Kunden in HTML umgewandelt, dann sah es so aus:

{{< figure src="./org-mode-html.png" >}}

Man sieht in beiden Dokumenten, das da Links enthalten sind. Wenn man drauf klickt,
kommt man erklärt, wie man das Testen kann. Das hat der Kunde genutzt, um zu prüfen,
ob seine Anforderungen auch wirklich erfüllt sind:

{{< figure src="./barebox-beeper.png" >}}

So nebenbei hat dann der Kunde alles über Linux-Utilities wie "`ifconfig`",
"`candump`" etc gelernt :-) Außerdem hat der Kunde den "First-Level Support"
selbst gemacht, also kaputte Geräte ausgetauscht und schonmal Fehlersuche
gemacht. Da war es natürlich hilfreich, (fast) alle Low-Level-Dinge dokumentiert
zu haben.


## Verwandte Projekte {#verwandte-projekte}

Die folgenden Projekte sind mit diesem Projekt verwandt:

-   [ Automatische Image-Erstellung ]({{< relref "mkimage" >}})
-   [ Dynamischer Flash-Schutz ]({{< relref "dynamischer-flashschutz" >}})
