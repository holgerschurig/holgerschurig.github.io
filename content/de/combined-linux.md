+++
title = "Combined-Linux: ein Image für viele Geräte"
author = ["Holger Schurig"]
date = 2024-01-16
tags = ["qt", "c++", "linux"]
categories = ["job"]
draft = false
+++

Hier ging es darum, ein und dasselbe Linux-Image auf eine Vielzahl von Geräte zu portieren.

Dies stand im Gegensatz zu den Windows- und Windows-Embedded-Images. Hier wurde
für jedes Gerät ein eigenes Image erstellt. Gab es eine Innovation, mussten alle
diese Image jeweils neu erstellt werden --- ein zeitraubender Prozess.

Ich wollte ein "Combined Linux" machen: eine Image, das alle Features in sich
enthält. Das man überall installieren kann. Das die Hardware erkennt und die
jeweils eingebaute Hardware passend anspricht und zur Verfügung stellt.

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Projekt-Info](#projekt-info)
- [Basis: Debian-Linux](#basis-debian-linux)
- [Anpassen ... aber an was?](#anpassen-dot-dot-dot-aber-an-was)
    - [Stapler-Terminals](#stapler-terminals)
    - [Tragbare Terminals](#tragbare-terminals)
    - [Fahrzeug-Computer](#fahrzeug-computer)
    - [Industrie-Panel-PCs](#industrie-panel-pcs)
- [Hardware erkennen](#hardware-erkennen)
    - [String im BIOS](#string-im-bios)
    - [DMI](#dmi)
    - [PCI-IDs testen](#pci-ids-testen)
- [Userspace](#userspace)
    - [GUI anpassen](#gui-anpassen)
    - [Daemons anpassen](#daemons-anpassen)
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

Idee: Kunden (das es Linux-Images geben sollte), ich (das man alle Gerätetypen
in ein Image kombinieren sollte)

Zuarbeit: Zusatz-Ideen kamen von PSS (Product Support Services), FAE (Field
Application Engineers), PMs (Produkt/Project Manager, allerdings eher wenig) und
auch direkt von Kunden

Umsetzung: ich

Nutzung: 2012 bis heute

Effizienzgewinn:

-   ein Image statt über 20 Images erstellen ist ein erheblicher Zeitgewinn
-   (man könnte argumentieren, das es beim Test eine kombinatorische Explosion
    gibt. Das ist aber nicht der Fall, da vor Auslieferung von Gerät+Linux-Image
    dies sowieso von FAE und Kunden geprüft und dann in einer spezifischen
    Hardware/Softwareversion freigegeben und festgezurrt wurde)


## Basis: Debian-Linux {#basis-debian-linux}

Basis war Debian-Linux.

Heutzutage ist Ubuntu viel bekannter, aber bei Projektstart war dies nicht der
Fall. Außerdem ist Ubuntu auf das Desktop-Metapher optimiert. In
Industrie-Anwendungen will man aber z.B. keinen Start-Button haben. Man möchte
(i.d.R.) nicht, das beim Einstecken eines USB-Sticks ein Dialog aufpoppt. Im
Prinzip braucht man überhaupt nichts aus der Desktop-Metapher.

Stattdessen möchte man fast immer nur einige einzige Anwendung haben, exclusiv,
im "Kiosk-Modus". Also nicht abbrechbar und ohne Wechselmöglichkeit. Also warum
ein Icon haben, das man anklicken muss, wenn die Applikation auch direkt
gestartet werden kann?

Schließlich will niemand, das Lagerarbeiter Tetris spielen ...


## Anpassen ... aber an was? {#anpassen-dot-dot-dot-aber-an-was}

Die unterstützten Geräte (siehe unten) habe unterschiedliche ...

-   Anzahl Ethernet-Karten: 0 bis 2
-   Anzahl WLAN-Karten: 0 bis 1
-   Anzahl WWAN-Karten (GSM, UMTS etc): 0 bis 1
-   Anzahl NFC-Interfaces: 0 bis 1
-   Anzahl Bluetooth-Interfaces: 0 bis 1
-   unterschiedliche Auflösungen
-   unterschiedliche Tasten auf der Frontplatte
-   unterschiedliche Touchscreen-Technologien (resistiv, kapazitiv) und Touchscreen-Controller-ICs
-   unterschiedliche Beleuchtungskonzepte (Backlight, Keyboard ...)
-   unterschiedliche Barcode-Scanner (keine, Symbol, Intermec, Honeywell, seriell, Bluetooth)
-   ... und viele Unterschiede mehr

Jedoch sollte die Software im "Combined-Linux" Image sich dynamisch auf die
Gegenheiten anpassen, beispielsweise welche Einstellungsmöglichkeit im
"`config`" GUI-Programm angezeigt werden.

Hier Beispiele für die Geräteklassen:


### Stapler-Terminals {#stapler-terminals}

{{< figure src="./staplerterminals.jpg" >}}

-   IPC7 (DLoG)
-   MPC6 (DLoG)
-   MTC6 (DLoG)
-   MTC6 mit AMD CPU
-   DLT-V83 (DLoG)
-   DLT-V83 Atom (DLoG)
-   DLT-V83 Celeron (DLoG)
-   DLT-V83 Facelift (Advantech)
-   DLT-V83 i5 (DLoG)
-   DLT-V72 (DLoG)
-   DLT-V72 Facelift (Advantech)
-   DLT-V72 mit voller Tastatur (DLoG)
-   DLT-V73 x86 (Advantech)
-   DLT-V62 (Advantech)
-   DLT-M81 (Advantech)

Werden in Stapler- oder Kommissionierfahrzeuge eingebaut. Manchmal auch in
Hochregal-Bedienfahrzeuge, Logistik-Hängebahnen, Portalkräne etc.


### Tragbare Terminals {#tragbare-terminals}

{{< figure src="./handterminals.jpg" >}}

-   DT362 (Digital Research)
-   S10A (Advantech)
-   PWS-770 (Advantech)
-   PWS-870 (Advantech)

Diese Geräte nimmt man in die Hand und kann sich damit frei bewegen. Auf den
Fotos sieht man das nicht, aber sie haben einen eingebauten Barcode-Scanner.


### Fahrzeug-Computer {#fahrzeug-computer}

{{< figure src="./fahrzeugcomputer.jpg" >}}

-   TREK-753 (Advantech)

Diese sind dazu gedacht, in KFZ eingebaut zu werden, beispielsweise in Bussen,
als Steuergerät für "Vehicle Smart Displays". Aber mit Linux drauf kann man sie
auch für andere Dinge einsetzen ...


### Industrie-Panel-PCs {#industrie-panel-pcs}

{{< figure src="./panelpcs.jpg" >}}

-   UTC-210 (Advantech)
-   UTC-520 (Advantech)

Werden in der Industrie zum Anzeigen allgemeiner Informationen genutzt,
beispielsweise an den Fließbändern von Auto-Herstellern.


## Hardware erkennen {#hardware-erkennen}

Man muß nun den Gerätetyp einwandfrei erkennen. Wie macht man das am besten, damit
man keine Falscherkennungen hat?

{{< figure src="hwdetect.png" >}}


### String im BIOS {#string-im-bios}

Die von DLoG oder Advantech (sie haben DLoG aufgekauft) selbst produzierten Geräte
hatten im BIOS einen speziell formatieren String hinterlegt. Der hat das Gerät,
aber auch die Version des BIOS kodiert.

Eine Wildcard-Suche prüfte dann in einem definierten physikalischen Speicherbereich, ob
es einen String wie z.B. "M6I??C??" gibt.

Das hat ein Linux-Kernel-Modul gemacht, da hierbei einfach auf physikalischen
Speicher zugegriffen werden kann. Ein Linux-Userspace-Programm kann das zwar
auch, müsste aber als "root" laufen.

```text
  // Mem start, length,  Wildcard + len, Device,  Human text
  { 0x000f0000, 0xffffe, "G6I??C??",  8, IS_DEVA, "Device A" },
  { 0xfff40000, 0x80000, "G6A??C??",  8, IS_DEVB, "Device A mit AMD" },
```

Das Kernelmodul wird automatisch geladen und stellt sein Ergebnis via
"`/proc/...`" Pseudo-Datei zur Verfügung. Darauf können alle Programme
zugreifen, "root" oder nicht.

Bei den Geräten, die einen BIOS-String haben, kamen wir auf 100% Erkennungsrate
und 0% Fehlerrate.


### DMI {#dmi}

Leider gab es Hardware, bei der das nicht funktionierte: Geräte die nicht unter den
Einfluss von DLoG designed wurden (beispielsweise die Treks, die UTCs, die PWS).

Aber in einigen Fällen sind die Informationen des [DMI](https://de.wikipedia.org/wiki/Desktop_Management_Interface) brauchbar. Als Kernel-Modul kommt
man da recht einfach dran:

```c
  vendor  = dmi_get_system_info(DMI_SYS_VENDOR);
  product = dmi_get_system_info(DMI_PRODUCT_NAME);
```

Das Ergebnis kann man gegen Soll-Werte vergleichen und weiß dann, auf welcher Hardware
man ist.

Bei den Geräten, die einen DMI-String haben, kamen wir auf 100% Erkennungsrate
und 0% Fehlerrate.


### PCI-IDs testen {#pci-ids-testen}

Erstaunlicherweise gibt es viel DMIs, die schlecht gepflegt sind. Da steht dann
z.B. "to be filled by O.E.M.", womit man nichts anfangen kann. Außer vielleicht
darauf schließen, das der Hersteller keine Liebe zum Detail hat und
unvollständige Arbeit abliefert.

Man braucht als leider eine Rückfalloption. Dazu dienten PCI-IDs. Im Linux-Userspace
kann man diese mit "`lspci -nn`" sehen --- und selbstverständlich kommt ein

```text
  // Host bridge
  { 0x8086, 0x0a04, IS_DEVA | IS_DEVB },           // Intel Corporation Haswell-ULT DRAM Controller
  { 0x8086, 0x0bf1, IS_DEVC },                     // Intel Corporation Atom Processor D2xxx DRAM Controller
  { 0x8086, 0x0f00, IS_DEVD | IS_DEVE | IS_DEVF},  // Intel Corporation Atom Processor Z36xxx/Z37xxx Series SoC

  // PCI Bridge
  ...

  // SATA
  ...

  // USB-Controller
  ...
```

Wie man gut sieht, reicht die Host-Bridge 8086:0a04 nicht aus, um ein Gerät
eindeutig zu indentifizieren. Denn sie kommt auf mehreren Geräten vor.

Wenn man jedoch die Informationen der anderen PCI-IDs hinzufügt (mit "..."
angedeutet), klappt es evtl doch.

Damit konnte ich dann die Hardware-Erkennung für all die Geräte "erschlagen",
die weder BIOS-Strings noch DMI-Strings hatten. Jedoch ... wird das Image auf
einem unbekanntem Gerät ausgeführt, kann es Fehlerkennungen geben.


## Userspace {#userspace}


### GUI anpassen {#gui-anpassen}

Nachdem die Hardware einmal erkannt ist, ist es leicht, darauf zu reagieren.

Das "`config`" GUI ist in C++/Qt geschrieben.

Darauf aufsetzend wurden Funktionen definiert die mit "`isXXX()`" bzw "`hasXXXX()`"
anfangen. Die is-Funktionen prüfen auf eine Gerät, die has-Funktionen prüfen
auf eine Funktion (hat Bluetooth, hat Backlight, hat USB-Gerät XXXX:YYYY).

Dadurch ist das Anpassen, hier z.B. des grafischen Menüs, ziemlich einfach:

```text
    if (isDevA() || isDevE() || isDemo())
        addIcon(tr("Backlight"), ":/images/backlight.svg", SLOT(clickedBacklight()) );
```


### Daemons anpassen {#daemons-anpassen}

Auch Daemons müssen sich an die sehr unterschiedlicher Hardware anpassen. Dort
geht dies genauso einfach, hier am Beispiel des "`scannerd`":

```text
    if (isDevA()) {
        port = "/dev/ttyS1";
        serialReader = new ReadIntermec(port, 19200, this);
        serialReconnect = true;
    } else
    if (isDevE()) {
        port = "/dev/ttyS1";
        serialReader = new ReadHoneywell(port, 115200, this);
        serialReconnect = true;
    } else
```


## Verwandte Projekte {#verwandte-projekte}

Die folgenden Projekte verwenden (teils abgewandelt) das Combined Image:

-   [ Automatische Image-Erstellung ]({{< relref "mkimage" >}})
-   [ Dynamischer Flash-Schutz ]({{< relref "dynamischer-flashschutz" >}})
-   [ Linux-Image auf Basis von i.MX6 RISC Prozessor für den Tagebau ]({{< relref "mkarm" >}})
-   TODO(Artikel schreiben) Linux Restore Stick
-   [ Hardware-Teststick für DLT-V83/DLT-V72 ]({{< relref "hwtester" >}})
-   TODO(Artikel schreiben) Hardware-Teststick für DLT-V73
-   TODO(Artikel schreiben) Aufräumen in Fukushima
