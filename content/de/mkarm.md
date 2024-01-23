+++
title = "Linux-Image auf Basis von i.MX& RISC Prozessor für den Tagebau"
author = ["Holger Schurig"]
date = 2024-01-22
tags = ["arm", "can", "embedded", "imx6", "linux", "openembedded", "qemu-user-status"]
categories = ["job"]
draft = false
+++

Wie man sich das zeitaufwändige Cross-Compilieren mit OpenEmbedded spart. <br/>

Oder: Implementierung eines Linux-Images auf eine RISC-Platform für einen sehr <br/>
rauhen Anwendungsfall. <br/>

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

In Beiträgen der Kategorie [Job](/categories/job/) trage ich Projekte zusammen, die ich im Rahmen <br/>
meiner beruflichen Karriere federführend durchgeführt habe. Ich gehe dabei mit <br/>
Absicht nicht allzusehr auf Details an: die Interessen meiner Arbeitgeber sollen <br/>
ja nicht berührt werden. <br/>

</div>


## Projekt-Info {#projekt-info}

Idee: Kundenanforderung <br/>

Umsetzung: Barebox, Linux und Image: ich <br/>

Nutzung: US-amerikanischer Minenausrüster <br/>

Implementatierung: Make, Bash, Python, Meson, C, C++, Qt, Git, Emacs, qemu-user-static <br/>


## Projekt-Background {#projekt-background}

Ein US-amerikanischer Ausrüster von Minen (in Deutschland z.B. bei Kali &amp; Salz) <br/>
hat spezielle Terminals von uns genutzt --- diese Terminals besonders Robust und halten <br/>
auch starken und dauerhaften Erschütterungen stand. <br/>

{{< figure src="./ahs.jpg" >}} <br/>

Auf dem Foto sieht der Truck ganz klein aus --- tatsächlich ist aber ein Rad <br/>
schon höher als die dicksten SUVs. In diesem Video wird das Projekt vorgestellt: <br/>
<https://youtu.be/6Nw7q0t2A9o>. Wer aufpasst, kann zum Zeitstempel 0.37 einmal <br/>
kurz das Device sehen. <br/>

Der Kunde hatte auf ein Vorgängergerät WinCE eingesetzt --- aber aufgrund massiver <br/>
Fehler in Windows CE, die Microsoft nie behob, war er mit der Software sehr unzufrieden. <br/>

Nun sollte auf Linux umgestellt werden, wobei ich den Kunden half. Allerdings <br/>
wurde auch eine neue Gerätegeneration entwickelt, um den geänderten <br/>
Anforderungen entsprechen zu können. <br/>


## Komponentenauswahl {#komponentenauswahl}

Viele Hersteller von ICs behaupten "Wir haben Linux-Support". Doch vor allem bei <br/>
asiatischen Lieferanten haben die dann einmalig vor 4 Jahren von irgendwem einen <br/>
Treiber entwickeln lassen, der dann auch nur mit einem seit 4 Jahren veralteten <br/>
Linux-Kernel funktioniert. <br/>

Deswegen habe ich schon beim Projektdesign die Hardware-Entwicklung beraten, <br/>
welche Chips oder Hersteller (Marvell und Broadcomm rücken kaum mit Infos raus!) <br/>
man meiden sollte. <br/>


## Board-Bringup {#board-bringup}

Nachdem die ersten Prototypen PCBs da waren, ging es um den Board-Bringup. <br/>

Zunächst habe ich mit einem Freescale / NXP - Tool die Timing-Parameter des DRAM <br/>
herausgefunden. Der leitende Elektronikingeneur tat dasselbe --- und wir hatten komplett <br/>
verschiedene Werte, die jeweils beim anderen nicht funktionierte. Dies stellte sich als <br/>
Fertigungsprobleme heraus, die dann behoben werden. <br/>

Als Bootloader hatte ich diesmal nicht u-boot, sondern [Barebox](https://www.barebox.org) genommen. Der war <br/>
viel moderner programmiert, ähnlich wie der Linux-Kernel. Er hat sogar wie der <br/>
Linux-Kernel ein "Kconfig" System, das damals bei u-boot noch nicht existierte. <br/>
Auch hat er denselben Device-Tree genutzt, den ich dann auch für den <br/>
Linux-Kernel genommen habe. <br/>


## Images {#images}

Das Image wurde mit einem ähnlichen System erstellt wie im Artikel <br/>
[ Combined-Linux: ein Image für viele Geräte ]({{< relref "combined-linux" >}}) <br/>
beschrieben. Also **nicht** mit [ OpenEmbedded ]({{< relref "openembedded" >}}). Das <br/>
führte zu einer erheblichen Zeitersparnis. <br/>

Das lag daran, das es keinerlei Cross-Compilation gab. <br/>

Doch wie geht das, wenn der Entwicklerrechner "i386" als Architektur hat, das <br/>
Zielsystem aber "armhf"? <br/>

Ganz einfach: mit der Hilfe von QEMU. Viele Leute kennen dieses Tool, normal <br/>
simuliert es komplette Rechner, also CPU, RAM, Flash, Devices. Aber es gibt auch <br/>
[qemu-user-static](https://github.com/multiarch/qemu-user-static). Dieses simuliert nur die CPU. Keinerlei Hardware ... sämtliche <br/>
Aufrufe von Linux-Kernel-Funktionen wie "`open()`", "`read()`" etc werden <br/>
stattdessen einfach an den Host-Kernel (also mein i386/amd64 -Kernel) übergeben. <br/>
Der führt das dann ganz normal aus. <br/>

Damit das klappt, nutzt man "`binfmt-misc`". Das ist ein Subsystem des Kernels. <br/>
Wenn ein Executable ausgeführt wird, schaut er sich die ersten Bytes an, <br/>
vergleicht diese mit ihm vorher bekannt gemachten Signaturen und startet dann <br/>
das Binary halt nicht direkt, sondern über ein Hilfsprogramm. <br/>


### Basis-Image: multistrap statt Debootstrap {#basis-image-multistrap-statt-debootstrap}

... oder besser: multistrap. Das war damals besser für fremde Architekturen <br/>
geeignet als debootstrap. Debootstrap selbst habe ich ja bereits <br/>
[ hier ]({{< relref "mkimage#debootstrap" >}}) beschrieben. <br/>

Also geht's hier mal um Multistap. <br/>

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

Die Zeilen [4](#org-coderef--f87743-4) und [16](#org-coderef--f87743-16) sind hier die "Secret Sauce". Zunächst müssen wir <br/>
ja dafür sorgen, das der Kernel "armhf" Binaries überhaupt ausführen kann --- bei heutigen <br/>
Debian-Versionen wird "`update-binfmts`" übrigens schon beim Booten ausgeführt. <br/>

Dann müssen wir natürlich noch das "`qemu-arm-static`" Binary (ein i386 btw <br/>
amd64) Binary in das armhf-Image-Directory kopieren. Sonst wäre es ja nach dem <br/>
"`chroot`" nicht erreichbar. Es ist, wie der Name schon andeutet, statisch <br/>
kompiliert. Es lädt also keinerlei Libraries aus "`/lib`" bzw "`/usr/lib`" <br/>
nach... denn im "`chroot`" wären die ja von der falschen Architektur und könnten <br/>
sowieso nicht geladen werden. <br/>

Das besondere an "`multistrap`" war, das es alle Debian-Pakete zwar ausgepackt <br/>
hat, dann aber die viele Scripte "`image.base/var/lib/dpkg/info/*.postinst`" <br/>
**nicht** ausgeführt hat. Das hätte ja nicht geschehen können, da "`multistrap`" <br/>
ja selbst noch unter i386/amd64 lief. Die Scripte aber rufen oft Binaries wie <br/>
z.B. "`addgroup`" auf. Und in "`image.base/`" sind diese halt von der <br/>
Architektur "`armhf`". <br/>

Die installierten Pakete sind also sozusagen noch nicht konfiguriert. <br/>

Deswegen wird in Zeile [21](#org-coderef--f87743-21) das Konfigurieren nachgeholt: "`dpkg --configure
-a`" wird mit Hilfe von "`chroot`" innerhalb von "`image.base/`" aufgerufen. <br/>
Dadurch werden alle "`*.post`" Scripte aufgerufen. Mittlerweile ist aber <br/>
"`qemu-user-static`" im Image verfügbar, und die Scripte können nach Herzenslust <br/>
"armhf" Binaries nutzen. <br/>


### Wie man (nicht) cross-compiliert {#wie-man--nicht--cross-compiliert}

Will (oder muss) man dann aber doch compilieren, geht auch das sehr einfach. <br/>

Ich kann das Basis-Image von "`image.base/`" nach "`image.dev`" kopieren und <br/>
dann dort alles installieren, was ich so zum Compilieren brauche: gcc, make, <br/>
cmake, meson, ninja, diverse \*-dev Libraries etc etc. <br/>

Und wenn ich dann mit "`chroot`" in dieses "`image.dev`" wechsle, kann ich <br/>
dort "armhf" Binaries direkt compilieren --- obwohl mein Host eigentlich <br/>
"i386" oder "amd64" Architektur hat. <br/>

Das ist ein wenig langsamer als native zu compilieren. Denn der <br/>
"`qemu-user-static`" emuliert schließlich eine CPU, dadurch wird der komplette <br/>
Compilationsprozess ja emuliert. <br/>

Aber es ist immer noch schneller als mit OpenEmbedded, da man ja nicht erst ein <br/>
Staging-Directory mir "armhf"-Libraries bevölkern muss. <br/>

Hier ist ein Beispiel, wie ich "`x11vnc`" (nicht) cross-compiliert habe: <br/>

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

Mit obigen Makefile-Snippets reicht ein "`make compvnc`" aus, das <br/>

-   eine bestimme Version der x11vnc-Sourcen heruntergeladen werden (falls sie noch nicht da sind) <br/>
-   dieser Source wird ausgepackt <br/>
-   mit lokalen Patches versehen (die ich also im eigenen GIT habe) <br/>
-   mit meinen Konfigurationsoptionen konfiguriert <br/>
-   und kompiliert <br/>

Anschließend hat man in "`image.dev/x11vnc/x11vnc`" das Binarie, das ich dann z.B. ins Kundenimage <br/>
kopieren kann. <br/>

Ich kann aber in "`image.dev`" auch reguläre Debian-Pakete erzeugen, aber das <br/>
sprengt diesen Post. <br/>


### Kunden-Images {#kunden-images}

Mit dem nur leicht abgewandelten im Post [ Automatische Image-Erstellung ]({{< relref "mkimage" >}}) wurden <br/>
dann im Laufe der Jahre drei Kunden-Images erstellt: <br/>

-   eines mit Java (der Kunde hatte seine Anwendung in Java geschrieben) <br/>
-   eines mit Mono (eine andere Anwendung wurde in C# geschrieben) <br/>
-   eines komplett ohne X11 und GUI (für eine Version des Gerätes ohne Display) <br/>

Je nachdem, welches Image ich (reproduzierbar) erstellt habe, dauerte dies 3 bis <br/>
6 Minuten. <br/>


## Linux-Kernel {#linux-kernel}

Auch hier wurde ein Linux-Kernel "dem Gerät auf den Leib geschneidert", also vom Source compiliert. <br/>

Netterweise hat sowohl Freescale als auch NXP (kaufen Freescale auf) mit der <br/>
Kernel-Community mitgearbeitet. Zwar hatten sie ihren eigenen Vendor-Kernel, wie <br/>
üblich hoffnungslos veraltet. Aber: sie brachten jeden Treiber "upstream" in den <br/>
offiziellen Linux-Kernel. Und dort haben dann die Subsysten-Maintainer immer ein Auge drauf <br/>
geworfen und teils drastische Verbesserungen erreicht. <br/>

Ich entschied mich also, einfach einen Kernel von <https://kernel.org> zu <br/>
verwenden: alle vom Kunden i.mX6 Subsystem wurden von ihm unterstützt. <br/>

Eine Besonderheit gab es aber bei CAN-Bus: hier hatte der Kunde hohe Anforderungen. Und <br/>
der CAN-Treiber vom offiziellen Linux-Kernel fiel durch. Der CAN-Treiber des Vendor-Kernels <br/>
(der ziemlich anders aussah) ... fiel auch durch. Hier habe ich mich dann in den Treiber <br/>
eingefuchst und habe dann einen Patch gemacht, der die sog. "Mailboxes" verwendet. <br/>

Nachdem der Kunde das getestet und für gut befunden hatte ... hat der <br/>
Linux-CAN-Maintainer einen ähnliche Änderung im offiziellen Linux-Kernel <br/>
eingebracht. Die haben wir dann übernommen --- was im Upstream-Kernel ist, wird <br/>
ja mit jeder Kernel-Version gepflegt. Was man "out-of-tree" hat, unterliegt <br/>
hingegen immer dem "Bitrot". Man ist damit nie so zukunftssicher. <br/>


## Kleinere Tools {#kleinere-tools}

-   uccomm (von µC-Communication): sprach mit den Microcontroller auf der <br/>
    Hauptplatine, um z.B. das Ein/Ausschaltverhalten zu steuern oder die Seriennummer <br/>
    auszulesen <br/>
-   Tool zum Einstellen des Hardware-Watchdog <br/>
-   Tool zur Device-Discovery (eine proprietäre Kundenlösung, kein mDNS oder SSDP) <br/>
-   ubloxcomm: von u-Blox gibt es tolle Einstellungsprogramme für ihre Chips ... <br/>
    leider damals nur für Windows. Also habe ich ein Tool geschrieben, welches das <br/>
    von der Kommandozeile machen konnte, da ich nichts vergleichbares gefunden in <br/>
    der Open-Source-Community gefunden hatte. Die Besonderheit war, das ich <br/>
    basierend auf eine Konfigurationsdatei beliebige Kommandos senden konnte --- <br/>
    auch für diesen Chip [undokumentierte](https://wiki.openstreetmap.org/wiki/U-blox_raw_format), die er aber anstandslos ausführte. <br/>
    Dieser Auszug aus der Konfigurationsdatei ermöglicht die Kommandos "`ubloxcomm
        sbas_on`", "`ubloxcomm sbas_off`" und "`ubloxcomm sbas_poll`": <br/>

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

Die Zeilen konntena auch mehrfach auftauchen. Um z.B. den NMEA-Output via <br/>
"`ubloxcomm nmea_off`" abzustellen, hat die Konfigurationsdatei dies vorgesehen: <br/>

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

Man kann aus diesen Auszügen auch sehe, das ich normalerweise immer gut <br/>
dokumentiere. Im Header der Datei steht exakt der Name und die Version des PDF, <br/>
auf die sich die Seitennummern beziehen. <br/>


## Projekt-Tracking {#projekt-tracking}

Es gab eine umfangreiche "Requirement Spec" vom Kunden, die sich allerdings <br/>
recht häufig geändert hat. Der Grund war, das dem Kunden Linux neu war. Dinge <br/>
wie "Priviledge Separation" waren ihm beispielsweise unbekannt. Wenn ich eine <br/>
neue Spec bekam, habe ich das Word-Dokument immer mit der vorherigen Version <br/>
verglichen, die Änderungen festgestellt --- diese Kunde hat die <br/>
Revisionshistorie nur unzureichend geführt ---. Und dann habe ich manchmal <br/>
gedacht "Also, so wie das gewünscht wird ist das nicht Best Practice". <br/>

In den wöchentlichen Telcos, oder manchmal zwischendurch per E-Mail, habe ich dann <br/>
Änderungesvorschläge gemacht und die Gründe erläutert. Nahezu immer wurde dies <br/>
dann berücksichtigt. <br/>

Um diese sich ändernden Anforderungen zu tracken habe ich das Kunden-Requirement <br/>
in eine eigene Emacs [org-mode](https://orgmode.org/) Datei überführt. <br/>

Ich habe auch eigene Sub-Punkte mit hineingenommen --- dem Kunden war es <br/>
beispielsweise egal, ob i2c im Bootloader geht oder nicht. Aber mir nicht, da <br/>
ich schon im Bootloader auf diverse i2c-Geräte zugreifen wollte. Also habe ich <br/>
dies dann mit einem eigenen TODO-Punkt versehen. <br/>

Org-mode kann man sich wie den Source eines Wiki vorstellen --- man kann es also, <br/>
da es Text ist (im Gegensatz zu einer Word-Datei) mit in "`git`" aufnehmen. Im Editor <br/>
sieht das dann ungefähr so aus: <br/>

{{< figure src="./org-mode.png" >}} <br/>

(Dies ist übrigens ein Auszug aus den Anforderungen des Bootloaders. Beispielsweise <br/>
sollte er beim Booten piepsen, also mußte er den "Beeper" unterstützen). <br/>

Ich habe das dann aber dem Kunden in HTML umgewandelt, dann sah es so aus: <br/>

{{< figure src="./org-mode-html.png" >}} <br/>

Man sieht in beiden Dokumenten, das da Links enthalten sind. Wenn man drauf klickt, <br/>
kommt man erklärt, wie man das Testen kann. Das hat der Kunde genutzt, um zu prüfen, <br/>
ob seine Anforderungen auch wirklich erfüllt sind: <br/>

{{< figure src="./barebox-beeper.png" >}} <br/>

So nebenbei hat dann der Kunde alles über Linux-Utilities wie "`ifconfig`", <br/>
"`candump`" etc gelernt :-) Außerdem hat der Kunde den "First-Level Support" <br/>
selbst gemacht, also kaputte Geräte ausgetauscht und schonmal Fehlersuche <br/>
gemacht. Da war es natürlich hilfreich, (fast) alle Low-Level-Dinge dokumentiert <br/>
zu haben. <br/>


## Verwandte Projekte {#verwandte-projekte}

Die folgenden Projekte sind mit diesem Projekt verwandt: <br/>

-   [ Automatische Image-Erstellung ]({{< relref "mkimage" >}}) <br/>
-   [ Dynamischer Flash-Schutz ]({{< relref "dynamischer-flashschutz" >}})

