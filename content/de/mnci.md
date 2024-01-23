+++
title = "MNCI: Handterminal mit ARM (Intel PXA320)"
author = ["Holger Schurig"]
date = 2024-01-20
tags = ["arm", "bdi2000", "boundary-scan", "c", "c++", "libertas", "linux", "openembedded", "pxa320", "qt", "qt/embedded", "telnet", "tn5250", "u-boot"]
categories = ["job"]
draft = false
+++

Hier stelle ich ein komplexes Projekt vor, bei dem ich federführend die gesamte <br/>
Software erstellt habe. <br/>

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

In Beiträgen der Kategorie [Job](/categories/job/) trage ich Projekte zusammen, die ich im Rahmen <br/>
meiner beruflichen Karriere federführend durchgeführt habe. Ich gehe dabei mit <br/>
Absicht nicht allzusehr auf Details an: die Interessen meiner Arbeitgeber sollen <br/>
ja nicht berührt werden. <br/>

</div>


## Projekt-Info {#projekt-info}

Idee: Frau Wienkötter, eine großer Süddeutscher Spediteur <br/>

Umsetzung: im Prinzip mit ein Kernteam von nur 3 Leuten: ein externer <br/>
Elektronikentwickler, jemand der die gesamte Mechanik (Gehäuse, Tastatur, <br/>
Finishing) und Produktionsplanung machte. Und ich für die gesamte Software. <br/>

Implementatierung: C, C++, Qt/Embedded, OpenEmbedded <br/>


## Vorgeschichte {#vorgeschichte}

Ich arbeitete damals bei "M&amp;N Solutions GmbH" in Rosbach. Diese Firma hat Geräte <br/>
für die Logistik eingekauft (z.B. bei Intermec) und weiterverkauft. Dadurch <br/>
hatte sie schon eine Menge an Kontakte in die Logistikwelt, zu Speditionen und <br/>
auch Einzelhändlern. <br/>

Einer unserer Kunden suchte nun ein Handterminal für seine LKW-Fahrer. Damals <br/>
fand er im Markt noch nichts, was auf seine Anforderungen passte: <br/>

-   eingebauter Barcode-Scanner <br/>
-   eingebautes GSM-Modem <br/>
-   eingebautes WLAN <br/>
-   eingebaute Kamera (um bei Schäden Dokumentations-Fotos machen zu können) <br/>
-   etc etc etc <br/>

Und wenn es etwas gab, dann meist auf Windows CE Basis. Es war damals aber <br/>
schon allgemein bekannt, das Windows CE massive Probleme im Netzwerkbereich hatte. <br/>
So konnte es beispielsweise abstürzen, wenn es per WLAN eine sehr hohe Anzahl <br/>
von Access-Points empfängt --- ein Puffer lief über, und man hatte viel Spaß. <br/>

Also wollte man dies mit Linux versuchen. <br/>


## Zum Gerät<span class="org-target" id="org-target--geraet"></span> {#zum-gerät}

Hier zunächst eine Gesamtsicht der drei Komponenten: <br/>

-   Handterminal "MNCI" <br/>
-   austauschbarer Akku <br/>
-   Docking-Station <br/>

{{< figure src="./mnci_akku_dock.jpg" >}} <br/>

Das Gerät hat einen flexiblen "Handstrap", damit es gut in der Hand liegt. Im Inneren <br/>
kann man eine SIM-Karte einstecken ... damals waren die noch etwas größer als heute :-) <br/>

{{< figure src="./mnci_sim.jpg" >}} <br/>

Damit ein Fahrer die Abgabe bzw. eventuelle Schäden dokumentieren kann, gibt es eine <br/>
Kamera. Und natürlich eine Laser-basierten Barcode-Scanner: <br/>

{{< figure src="./mnci_camera_barcode.jpg" >}} <br/>

Auf der Front befinden sich <br/>

-   Tastatur <br/>
-   resistiver Touchscreen <br/>
-   Mikrofon und Lautsprecher <br/>

{{< figure src="./mnci_front.jpg" >}} <br/>

(und ja, man konnte den MNCI als Telefon nutzen. Eines der klobisten Telefone <br/>
seiner Zeit ...) <br/>

Am unteren Ende gibt es jede Menge Anschlüsse: <br/>

-   USB (beispielsweise zu Barcode-Druckern) <br/>
-   Infrarot (keine Ahnung wofür, wurde von keinem Kunden je verwendet) <br/>
-   externe GSM-Antenne (damit das Gerät während der Fahrt im LKW gute Verbindung bekommt) <br/>
-   Audio-Ausgang (ebenfalls damit man im LKW das Gerät hören kann) <br/>
-   Anschluss gehen zur Docking-Station <br/>

{{< figure src="./mnci_unten.jpg" >}} <br/>

Die vielen Pins zur Docking-Station haben einen Grund. Denn dort findet man <br/>

-   Stromversorgung <br/>
-   zwei weitere serielle Ports <br/>
-   einen 10 MB/s Ethernet-Anschluss <br/>
-   eine Aufnahme um einen zweiten Akku laden zu können (der im Gerät wird auch <br/>
    geladen, wenn das Gerät gedockt ist) <br/>

{{< figure src="./mnci_dock.jpg" >}} <br/>


## Bootloader {#bootloader}

Die PXA320 CPU war mit Intel-StrataFlash ausgerüstet, dort war der Bootloader <br/>
u-boot, der Kernel und das Journalling Flash Filesystem (JFFS) gespeichert. <br/>

Den Bootloader habe ich an das Gerät angepaßt. <br/>

Die ersten Schritte waren dann: <br/>

1.  einen seriellen Port zum Leben erwecken (für Debug-Ausgaben) <br/>
2.  das DRAM initialisieren <br/>
3.  den Ethernet-Port initialisieren <br/>

Schritt 3 war für die weitere Entwicklung eine große Zeitersparnis. Besonders <br/>
wenn man neu in einem Feld ist --- Kernel hatte ich schon oft für i386 kompiliert, <br/>
aber noch nie für armhf --- bekommt man damit einen schnellen Turnaround hin. Man <br/>
sieht auch an den Debug-Ausgaben des Kernels sofort, ob man noch Treiberprobleme hat. <br/>

Als nächstes folgte <br/>

4.  dem Kernel eine initrd mit Busybox beigesellen <br/>

Damit konnte ich in eine Shell booten, damit waren dann sogar Tools wie "`i2cget`" oder <br/>
"`lsusb`" verfügbar. <br/>


## Flashen via Boundary-Scan {#flashen-via-boundary-scan}

Erst danach habe ich dem u-boot den Zugriff auf das Flash beigebracht. <br/>

Geflasht wurde das Gerät über nicht über u-Boot ... sondern über einen BDI2000. Das <br/>
ist eigentlich ein "Boundary-Scan-Device". In diesem Mode werden nahezu alle Pins <br/>
der CPU von den internen CPU-Blöcken getrennt und an ein Schieberegister gekoppelt. <br/>
Dort hinein kann der BDI2000 dann Bits hinein- bzw. hinausschieben. <br/>

Einerseits kann man Hardware-Tests machen ... man muss dafür keine Leiterbahnen <br/>
auftrennen und kann jedes Pin des Prozessors messen / setzen. <br/>

Andererseits kann man aber auch den Adress- und Datenbus "per Hand" bedienen und <br/>
so das Intel-Strataflash ohne Zutun der CPU programmieren. Das ging erstaunlich <br/>
schnell, ungefähr so schnell wie heute ein ST/LinkV2 das bei STM32-Prozessoren <br/>
kann. <br/>


## Linux-Kernel {#linux-kernel}

Ein Linux-Kernel aus der 3.x er Reihe wurde auf das Gerät angepaßt und <br/>
cross-compiliert. Für die [oben](#org-target--geraet) angeführten Geräte mussten natürlich Treiber her: <br/>

-   LCD-Display <br/>
-   Touchscreen <br/>
-   Hintergrundbeleuchtung (PWM) <br/>
-   Akku-Ladestand <br/>
-   serielle Ports (zu GSM, extern, Barcode-Laserscanner) <br/>
-   Kamera <br/>
-   Tastaturmatrix mit (normal, blaue Funktionsebene, rote Funktionsebene) <br/>
-   Audio (Mikrofon, Lautsprecher, via i2s) <br/>
-   USB <br/>
-   Infrarot <br/>
-   Ethernet <br/>

Aber es gab noch Geräte, die man auf den Fotos nicht sieht, beispielsweise <br/>

-   RTC (Datum / Uhrzeit) <br/>
-   Compact-Flash an sich <br/>
-   WLAN-Karte in Form einer Compact-Flash Karte auf Basis eines Marvell-Chips <br/>

Übrigens war dies zu Zeiten, als Device-Tree im Kernel noch nicht von allen <br/>
Treibern unterstützt war. Daher war die Implementierung des einen oder <br/>
anderen Treibers deutlich aufwändiger als heute. <br/>

Der Treiber für die Tastaturmatrix war eine gänzlich eigene Entwicklung. <br/>

Für den Libertas hatten wir --- dank des [One Laptop Per Child](https://de.wikipedia.org/wiki/OLPC_XO-1) Projektes zwar den <br/>
Source eines Treibers. Das ist gänzlich untypisch für Marvell, die mit <br/>
Dokumentationen geizt und knausert, es sei denn man macht ein NDA und nimmt <br/>
10000 Stück ab. Da sie aber ihre WIFI-Chips für OLPC verkaufen wollten, gab es <br/>
dazu Source ... aber ach, die Qualität ... zusammen mit einem anderen <br/>
Kernel-Programmierer habe ich dann die Qualität des Treibers drastisch <br/>
verbessert. Auch wurde die Struktur vereinfacht: vorher wurden manche Funktionen <br/>
über 3 oder 4 Indirektionen aufgerufen, das war ein wenig undurchsichtig und hat <br/>
nur unnötig den Code aufgebläht. All dies wurde vereinfacht. <br/>


## User-Space {#user-space}

Als User-Space kam ein Qt/Embedded Programm, geschrieben mit Qt 3.x zum Einsatz. <br/>
Es hatte einige allgemeine Einstellmöglichkeiten (z.B. IP-Adresse, SSID) und auch <br/>
Gerätespezifische (beispielsweise welche Barcodes akzeptiert werden sollten). <br/>

Außerdem war ein grafischer <br/>

-   Telnet-Client <br/>
-   TN5250-Client <br/>

eingebaut. Telnet wurde damals viel häufiger als heute verwendet. Und der eine <br/>
oder andere Logistiker hatte AS/400 in Benutzung. <br/>

Es gab selbstverständlich auch die Möglichkeit, das der Kunde sich selbst ein <br/>
Programm programmiert und installiert hätte. <br/>

Ich hatte Versuche mit einem Browser auf dem Gerät gemacht, für Webanwendungen. <br/>
Jedoch war das dann so lahm, das es unbrauchbar war. Weder die Taktfrequenz des <br/>
PXA320, noch sein DRAM-Throughput, noch die Größe des DRAM waren für <br/>
Browseranwendungen adequat. <br/>

X11 wurde nicht installiert, auch das war zu langsam. <br/>


## Projektende {#projektende}

Scheinbar hat die Chefin von M&amp;N mit dem Logistiker eine schlechte Übereinkunft <br/>
gemacht, denn uns wurde nicht die Entwicklungszeit bezahlt, sondern <br/>
Geräteabnahme versprochen. Auf Handschlag. <br/>

Nur stellte es sich heraus, das der Handschlag für den süddeutschen Logistiker <br/>
nichts wert war. Auf einmal waren wir ihn zu klein und popelig, mit unseren 30 <br/>
Leuten. Er hingegen wäre ja groß, mit Niederlassungen auf der ganzen Welt. <br/>

Es muss betont werden, das das Gerät in Revision 4 vollkommen funktionierte, <br/>
technisch gab es keine Beanstandungen. Weder von ihm noch von anderen Kunden. <br/>

Da die Entwicklung von M&amp;N teilweise kreditfinanziert war, dann aber kein <br/>
größerer Umsatz kam, wurde M&amp;N in die Insolvenz getrieben. Zwar wurden einige <br/>
MNCI-Geräte an andere Kunden verkauft. Aber zu wenige. Ein wirtschaftlicher <br/>
Erfolg stellte sich nicht ein. <br/>


## Verwandte Projekte {#verwandte-projekte}

Die folgenden Projekte sind verwandt mit diesem Projekt: <br/>

-   [ OpenEmbedded ]({{< relref "openembedded" >}}) <br/>
-   TODO(Artikel schreiben) WLAN-Treiber "Libertas"

