+++
title = "MNCI: Handterminal mit ARM (Intel PXA320)"
author = ["Holger Schurig"]
date = 2024-01-20
tags = ["arm", "bdi2000", "boundary-scan", "c", "c++", "embedded", "libertas", "linux", "openembedded", "pxa320", "qt", "qt/embedded", "telnet", "tn5250", "u-boot"]
categories = ["job"]
draft = false
+++

Hier stelle ich ein komplexes Projekt vor, bei dem ich federführend die gesamte
Software erstellt habe.

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Projekt-Info](#projekt-info)
- [Vorgeschichte](#vorgeschichte)
- [Zum Gerät](#zum-gerät)
- [Bootloader](#bootloader)
- [Flashen via Boundary-Scan](#flashen-via-boundary-scan)
- [Linux-Kernel](#linux-kernel)
- [User-Space](#user-space)
- [Projektende](#projektende)
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

Idee: Frau Wienkötter, eine großer Süddeutscher Spediteur

Umsetzung: im Prinzip mit ein Kernteam von nur 3 Leuten: ein externer
Elektronikentwickler, jemand der die gesamte Mechanik (Gehäuse, Tastatur,
Finishing) und Produktionsplanung machte. Und ich für die gesamte Software.

Implementatierung: C, C++, Qt/Embedded, OpenEmbedded


## Vorgeschichte {#vorgeschichte}

Ich arbeitete damals bei "M&amp;N Solutions GmbH" in Rosbach. Diese Firma hat Geräte
für die Logistik eingekauft (z.B. bei Intermec) und weiterverkauft. Dadurch
hatte sie schon eine Menge an Kontakte in die Logistikwelt, zu Speditionen und
auch Einzelhändlern.

Einer unserer Kunden suchte nun ein Handterminal für seine LKW-Fahrer. Damals
fand er im Markt noch nichts, was auf seine Anforderungen passte:

-   eingebauter Barcode-Scanner
-   eingebautes GSM-Modem
-   eingebautes WLAN
-   eingebaute Kamera (um bei Schäden Dokumentations-Fotos machen zu können)
-   etc etc etc

Und wenn es etwas gab, dann meist auf Windows CE Basis. Es war damals aber
schon allgemein bekannt, das Windows CE massive Probleme im Netzwerkbereich hatte.
So konnte es beispielsweise abstürzen, wenn es per WLAN eine sehr hohe Anzahl
von Access-Points empfängt --- ein Puffer lief über, und man hatte viel Spaß.

Also wollte man dies mit Linux versuchen.


## Zum Gerät<span class="org-target" id="org-target--geraet"></span> {#zum-gerät}

Hier zunächst eine Gesamtsicht der drei Komponenten:

-   Handterminal "MNCI"
-   austauschbarer Akku
-   Docking-Station

{{< figure src="./mnci_akku_dock.jpg" >}}

Das Gerät hat einen flexiblen "Handstrap", damit es gut in der Hand liegt. Im Inneren
kann man eine SIM-Karte einstecken ... damals waren die noch etwas größer als heute :-)

{{< figure src="./mnci_sim.jpg" >}}

Damit ein Fahrer die Abgabe bzw. eventuelle Schäden dokumentieren kann, gibt es eine
Kamera. Und natürlich eine Laser-basierten Barcode-Scanner:

{{< figure src="./mnci_camera_barcode.jpg" >}}

Auf der Front befinden sich

-   Tastatur
-   resistiver Touchscreen
-   Mikrofon und Lautsprecher

{{< figure src="./mnci_front.jpg" >}}

(und ja, man konnte den MNCI als Telefon nutzen. Eines der klobisten Telefone
seiner Zeit ...)

Am unteren Ende gibt es jede Menge Anschlüsse:

-   USB (beispielsweise zu Barcode-Druckern)
-   Infrarot (keine Ahnung wofür, wurde von keinem Kunden je verwendet)
-   externe GSM-Antenne (damit das Gerät während der Fahrt im LKW gute Verbindung bekommt)
-   Audio-Ausgang (ebenfalls damit man im LKW das Gerät hören kann)
-   Anschluss gehen zur Docking-Station

{{< figure src="./mnci_unten.jpg" >}}

Die vielen Pins zur Docking-Station haben einen Grund. Denn dort findet man

-   Stromversorgung
-   zwei weitere serielle Ports
-   einen 10 MB/s Ethernet-Anschluss
-   eine Aufnahme um einen zweiten Akku laden zu können (der im Gerät wird auch
    geladen, wenn das Gerät gedockt ist)

{{< figure src="./mnci_dock.jpg" >}}


## Bootloader {#bootloader}

Die PXA320 CPU war mit Intel-StrataFlash ausgerüstet, dort war der Bootloader
u-boot, der Kernel und das Journalling Flash Filesystem (JFFS) gespeichert.

Den Bootloader habe ich an das Gerät angepaßt.

Die ersten Schritte waren dann:

1.  einen seriellen Port zum Leben erwecken (für Debug-Ausgaben)
2.  das DRAM initialisieren
3.  den Ethernet-Port initialisieren

Schritt 3 war für die weitere Entwicklung eine große Zeitersparnis. Besonders
wenn man neu in einem Feld ist --- Kernel hatte ich schon oft für i386 kompiliert,
aber noch nie für armhf --- bekommt man damit einen schnellen Turnaround hin. Man
sieht auch an den Debug-Ausgaben des Kernels sofort, ob man noch Treiberprobleme hat.

Als nächstes folgte

4.  dem Kernel eine initrd mit Busybox beigesellen

Damit konnte ich in eine Shell booten, damit waren dann sogar Tools wie "`i2cget`" oder
"`lsusb`" verfügbar.


## Flashen via Boundary-Scan {#flashen-via-boundary-scan}

Erst danach habe ich dem u-boot den Zugriff auf das Flash beigebracht.

Geflasht wurde das Gerät über nicht über u-Boot ... sondern über einen BDI2000. Das
ist eigentlich ein "Boundary-Scan-Device". In diesem Mode werden nahezu alle Pins
der CPU von den internen CPU-Blöcken getrennt und an ein Schieberegister gekoppelt.
Dort hinein kann der BDI2000 dann Bits hinein- bzw. hinausschieben.

Einerseits kann man Hardware-Tests machen ... man muss dafür keine Leiterbahnen
auftrennen und kann jedes Pin des Prozessors messen / setzen.

Andererseits kann man aber auch den Adress- und Datenbus "per Hand" bedienen und
so das Intel-Strataflash ohne Zutun der CPU programmieren. Das ging erstaunlich
schnell, ungefähr so schnell wie heute ein ST/LinkV2 das bei STM32-Prozessoren
kann.


## Linux-Kernel {#linux-kernel}

Ein Linux-Kernel aus der 3.x er Reihe wurde auf das Gerät angepaßt und
cross-compiliert. Für die [oben](#org-target--geraet) angeführten Geräte mussten natürlich Treiber her:

-   LCD-Display
-   Touchscreen
-   Hintergrundbeleuchtung (PWM)
-   Akku-Ladestand
-   serielle Ports (zu GSM, extern, Barcode-Laserscanner)
-   Kamera
-   Tastaturmatrix mit (normal, blaue Funktionsebene, rote Funktionsebene)
-   Audio (Mikrofon, Lautsprecher, via i2s)
-   USB
-   Infrarot
-   Ethernet

Aber es gab noch Geräte, die man auf den Fotos nicht sieht, beispielsweise

-   RTC (Datum / Uhrzeit)
-   Compact-Flash an sich
-   WLAN-Karte in Form einer Compact-Flash Karte auf Basis eines Marvell-Chips

Übrigens war dies zu Zeiten, als Device-Tree im Kernel noch nicht von allen
Treibern unterstützt war. Daher war die Implementierung des einen oder
anderen Treibers deutlich aufwändiger als heute.

Der Treiber für die Tastaturmatrix war eine gänzlich eigene Entwicklung.

Für den Libertas hatten wir --- dank des [One Laptop Per Child](https://de.wikipedia.org/wiki/OLPC_XO-1) Projektes zwar den
Source eines Treibers. Das ist gänzlich untypisch für Marvell, die mit
Dokumentationen geizt und knausert, es sei denn man macht ein NDA und nimmt
10000 Stück ab. Da sie aber ihre WIFI-Chips für OLPC verkaufen wollten, gab es
dazu Source ... aber ach, die Qualität ... zusammen mit einem anderen
Kernel-Programmierer habe ich dann die Qualität des Treibers drastisch
verbessert. Auch wurde die Struktur vereinfacht: vorher wurden manche Funktionen
über 3 oder 4 Indirektionen aufgerufen, das war ein wenig undurchsichtig und hat
nur unnötig den Code aufgebläht. All dies wurde vereinfacht.


## User-Space {#user-space}

Als User-Space kam ein Qt/Embedded Programm, geschrieben mit Qt 3.x zum Einsatz.
Es hatte einige allgemeine Einstellmöglichkeiten (z.B. IP-Adresse, SSID) und auch
Gerätespezifische (beispielsweise welche Barcodes akzeptiert werden sollten).

Außerdem war ein grafischer

-   Telnet-Client
-   TN5250-Client

eingebaut. Telnet wurde damals viel häufiger als heute verwendet. Und der eine
oder andere Logistiker hatte AS/400 in Benutzung.

Es gab selbstverständlich auch die Möglichkeit, das der Kunde sich selbst ein
Programm programmiert und installiert hätte.

Ich hatte Versuche mit einem Browser auf dem Gerät gemacht, für Webanwendungen.
Jedoch war das dann so lahm, das es unbrauchbar war. Weder die Taktfrequenz des
PXA320, noch sein DRAM-Throughput, noch die Größe des DRAM waren für
Browseranwendungen adequat.

X11 wurde nicht installiert, auch das war zu langsam.


## Projektende {#projektende}

Scheinbar hat die Chefin von M&amp;N mit dem Logistiker eine schlechte Übereinkunft
gemacht, denn uns wurde nicht die Entwicklungszeit bezahlt, sondern
Geräteabnahme versprochen. Auf Handschlag.

Nur stellte es sich heraus, das der Handschlag für den süddeutschen Logistiker
nichts wert war. Auf einmal waren wir ihn zu klein und popelig, mit unseren 30
Leuten. Er hingegen wäre ja groß, mit Niederlassungen auf der ganzen Welt.

Es muss betont werden, das das Gerät in Revision 4 vollkommen funktionierte,
technisch gab es keine Beanstandungen. Weder von ihm noch von anderen Kunden.

Da die Entwicklung von M&amp;N teilweise kreditfinanziert war, dann aber kein
größerer Umsatz kam, wurde M&amp;N in die Insolvenz getrieben. Zwar wurden einige
MNCI-Geräte an andere Kunden verkauft. Aber zu wenige. Ein wirtschaftlicher
Erfolg stellte sich nicht ein.


## Verwandte Projekte {#verwandte-projekte}

Die folgenden Projekte sind verwandt mit diesem Projekt:

-   [ OpenEmbedded ]({{< relref "openembedded" >}})
-   TODO(Artikel schreiben) WLAN-Treiber "Libertas"
