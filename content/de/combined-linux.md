+++
title = "Combined-Linux: ein Image für viele Geräte"
author = ["Holger Schurig"]
date = 2024-01-16
tags = ["linux", "kernel", "c++", "Qt"]
categories = ["job"]
draft = false
+++

Hier ging es darum, ein und dasselbe Linux-Image auf eine Vielzahl von Geräte zu portieren. <br/>

Dies stand im Gegensatz zu den Windows- und Windows-Embedded-Images. Hier wurde <br/>
für jedes Gerät ein eigenes Image erstellt. Gab es eine Innovation, mussten alle <br/>
diese Image jeweils neu erstellt werden --- ein zeitraubender Prozess. <br/>

Ich wollte ein "Combined Linux" machen: eine Image, das alle Features in sich <br/>
enthält. Das man überall installieren kann. Das die Hardware erkennt und die <br/>
jeweils eingebaute Hardware passend anspricht und zur Verfügung stellt. <br/>

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

In Beiträgen der Kategorie [Job](/categories/job/) trage ich Projekte zusammen, die ich im Rahmen <br/>
meiner beruflichen Karriere federführend durchgeführt habe. Ich gehe dabei mit <br/>
Absicht nicht allzusehr auf Details an: die Interessen meiner Arbeitgeber sollen <br/>
ja nicht berührt werden. <br/>

</div>


## Projekt-Info {#projekt-info}

Idee: Kunden (das es Linux-Images geben sollte), ich (das man alle Gerätetypen <br/>
in ein Image kombinieren sollte) <br/>

Zuarbeit: Zusatz-Ideen kamen von PSS (Product Support Services), FAE (Field <br/>
Application Engineers), PMs (Produkt/Project Manager, allerdings eher wenig) und <br/>
auch direkt von Kunden <br/>

Umsetzung: ich <br/>

Nutzung: 2012 bis heute <br/>

Effizienzgewinn: <br/>

-   ein Image statt über 20 Images erstellen ist ein erheblicher Zeitgewinn <br/>
-   (man könnte argumentieren, das es beim Test eine kombinatorische Explosion <br/>
    gibt. Das ist aber nicht der Fall, da vor Auslieferung von Gerät+Linux-Image <br/>
    dies sowieso von FAE und Kunden geprüft und dann in einer spezifischen <br/>
    Hardware/Softwareversion freigegeben und festgezurrt wurde) <br/>


## Basis: Debian-Linux {#basis-debian-linux}

Basis war Debian-Linux. <br/>

Heutzutage ist Ubuntu viel bekannter, aber bei Projektstart war dies nicht der <br/>
Fall. Außerdem ist Ubuntu auf das Desktop-Metapher optimiert. In <br/>
Industrie-Anwendungen will man aber z.B. keinen Start-Button haben. Man möchte <br/>
(i.d.R.) nicht, das beim Einstecken eines USB-Sticks ein Dialog aufpoppt. Im <br/>
Prinzip braucht man überhaupt nichts aus der Desktop-Metapher. <br/>

Stattdessen möchte man fast immer nur einige einzige Anwendung haben, exclusiv, <br/>
im "Kiosk-Modus". Also nicht abbrechbar und ohne Wechselmöglichkeit. Also warum <br/>
ein Icon haben, das man anklicken muss, wenn die Applikation auch direkt <br/>
gestartet werden kann? <br/>

Schließlich will niemand, das Lagerarbeiter Tetris spielen ... <br/>


## Anpassen ... aber an was? {#anpassen-dot-dot-dot-aber-an-was}

Die unterstützten Geräte (siehe unten) habe unterschiedliche ... <br/>

-   Anzahl Ethernet-Karten: 0 bis 2 <br/>
-   Anzahl WLAN-Karten: 0 bis 1 <br/>
-   Anzahl WWAN-Karten (GSM, UMTS etc): 0 bis 1 <br/>
-   Anzahl NFC-Interfaces: 0 bis 1 <br/>
-   Anzahl Bluetooth-Interfaces: 0 bis 1 <br/>
-   unterschiedliche Auflösungen <br/>
-   unterschiedliche Tasten auf der Frontplatte <br/>
-   unterschiedliche Touchscreen-Technologien (resistiv, kapazitiv) und Touchscreen-Controller-ICs <br/>
-   unterschiedliche Beleuchtungskonzepte (Backlight, Keyboard ...) <br/>
-   unterschiedliche Barcode-Scanner (keine, Symbol, Intermec, Honeywell, seriell, Bluetooth) <br/>
-   ... und viele Unterschiede mehr <br/>

Jedoch sollte die Software im "Combined-Linux" Image sich dynamisch auf die <br/>
Gegenheiten anpassen, beispielsweise welche Einstellungsmöglichkeit im <br/>
"`config`" GUI-Programm angezeigt werden. <br/>

Hier Beispiele für die Geräteklassen: <br/>


### Stapler-Terminals {#stapler-terminals}

{{< figure src="./staplerterminals.jpg" >}} <br/>

-   IPC7 (DLoG) <br/>
-   MPC6 (DLoG) <br/>
-   MTC6 (DLoG) <br/>
-   MTC6 mit AMD CPU <br/>
-   DLT-V83 (DLoG) <br/>
-   DLT-V83 Atom (DLoG) <br/>
-   DLT-V83 Celeron (DLoG) <br/>
-   DLT-V83 Facelift (Advantech) <br/>
-   DLT-V83 i5 (DLoG) <br/>
-   DLT-V72 (DLoG) <br/>
-   DLT-V72 Facelift (Advantech) <br/>
-   DLT-V72 mit voller Tastatur (DLoG) <br/>
-   DLT-V73 x86 (Advantech) <br/>
-   DLT-V62 (Advantech) <br/>
-   DLT-M81 (Advantech) <br/>

Werden in Stapler- oder Kommissionierfahrzeuge eingebaut. Manchmal auch in <br/>
Hochregal-Bedienfahrzeuge, Logistik-Hängebahnen, Portalkräne etc. <br/>


### Tragbare Terminals {#tragbare-terminals}

{{< figure src="./handterminals.jpg" >}} <br/>

-   DT362 (Digital Research) <br/>
-   S10A (Advantech) <br/>
-   PWS-770 (Advantech) <br/>
-   PWS-870 (Advantech) <br/>

Diese Geräte nimmt man in die Hand und kann sich damit frei bewegen. Auf den <br/>
Fotos sieht man das nicht, aber sie haben einen eingebauten Barcode-Scanner. <br/>


### Fahrzeug-Computer {#fahrzeug-computer}

{{< figure src="./fahrzeugcomputer.jpg" >}} <br/>

-   TREK-753 (Advantech) <br/>

Diese sind dazu gedacht, in KFZ eingebaut zu werden, beispielsweise in Bussen, <br/>
als Steuergerät für "Vehicle Smart Displays". Aber mit Linux drauf kann man sie <br/>
auch für andere Dinge einsetzen ... <br/>


### Industrie-Panel-PCs {#industrie-panel-pcs}

{{< figure src="./panelpcs.jpg" >}} <br/>

-   UTC-210 (Advantech) <br/>
-   UTC-520 (Advantech) <br/>

Werden in der Industrie zum Anzeigen allgemeiner Informationen genutzt, <br/>
beispielsweise an den Fließbändern von Auto-Herstellern. <br/>


## Hardware erkennen {#hardware-erkennen}

Man muß nun den Gerätetyp einwandfrei erkennen. Wie macht man das am besten, damit <br/>
man keine Falscherkennungen hat? <br/>

{{< figure src="hwdetect.png" >}} <br/>


### String im BIOS {#string-im-bios}

Die von DLoG oder Advantech (sie haben DLoG aufgekauft) selbst produzierten Geräte <br/>
hatten im BIOS einen speziell formatieren String hinterlegt. Der hat das Gerät, <br/>
aber auch die Version des BIOS kodiert. <br/>

Eine Wildcard-Suche prüfte dann in einem definierten physikalischen Speicherbereich, ob <br/>
es einen String wie z.B. "M6I??C??" gibt. <br/>

Das hat ein Linux-Kernel-Modul gemacht, da hierbei einfach auf physikalischen <br/>
Speicher zugegriffen werden kann. Ein Linux-Userspace-Programm kann das zwar <br/>
auch, müsste aber als "root" laufen. <br/>

```text
  // Mem start, length,  Wildcard + len, Device,  Human text
  { 0x000f0000, 0xffffe, "G6I??C??",  8, IS_DEVA, "Device A" },
  { 0xfff40000, 0x80000, "G6A??C??",  8, IS_DEVB, "Device A mit AMD" },
```

Das Kernelmodul wird automatisch geladen und stellt sein Ergebnis via <br/>
"`/proc/...`" Pseudo-Datei zur Verfügung. Darauf können alle Programme <br/>
zugreifen, "root" oder nicht. <br/>

Bei den Geräten, die einen BIOS-String haben, kamen wir auf 100% Erkennungsrate <br/>
und 0% Fehlerrate. <br/>


### DMI {#dmi}

Leider gab es Hardware, bei der das nicht funktionierte: Geräte die nicht unter den <br/>
Einfluss von DLoG designed wurden (beispielsweise die Treks, die UTCs, die PWS). <br/>

Aber in einigen Fällen sind die Informationen des [DMI](https://de.wikipedia.org/wiki/Desktop_Management_Interface) brauchbar. Als Kernel-Modul kommt <br/>
man da recht einfach dran: <br/>

```c
  vendor  = dmi_get_system_info(DMI_SYS_VENDOR);
  product = dmi_get_system_info(DMI_PRODUCT_NAME);
```

Das Ergebnis kann man gegen Soll-Werte vergleichen und weiß dann, auf welcher Hardware <br/>
man ist. <br/>

Bei den Geräten, die einen DMI-String haben, kamen wir auf 100% Erkennungsrate <br/>
und 0% Fehlerrate. <br/>


### PCI-IDs testen {#pci-ids-testen}

Erstaunlicherweise gibt es viel DMIs, die schlecht gepflegt sind. Da steht dann <br/>
z.B. "to be filled by O.E.M.", womit man nichts anfangen kann. Außer vielleicht <br/>
darauf schließen, das der Hersteller keine Liebe zum Detail hat und <br/>
unvollständige Arbeit abliefert. <br/>

Man braucht als leider eine Rückfalloption. Dazu dienten PCI-IDs. Im Linux-Userspace <br/>
kann man diese mit "`lspci -nn`" sehen --- und selbstverständlich kommt ein <br/>

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

Wie man gut sieht, reicht die Host-Bridge 8086:0a04 nicht aus, um ein Gerät <br/>
eindeutig zu indentifizieren. Denn sie kommt auf mehreren Geräten vor. <br/>

Wenn man jedoch die Informationen der anderen PCI-IDs hinzufügt (mit "..." <br/>
angedeutet), klappt es evtl doch. <br/>

Damit konnte ich dann die Hardware-Erkennung für all die Geräte "erschlagen", <br/>
die weder BIOS-Strings noch DMI-Strings hatten. Jedoch ... wird das Image auf <br/>
einem unbekanntem Gerät ausgeführt, kann es Fehlerkennungen geben. <br/>


## Userspace {#userspace}


### GUI anpassen {#gui-anpassen}

Nachdem die Hardware einmal erkannt ist, ist es leicht, darauf zu reagieren. <br/>

Das "`config`" GUI ist in C++/Qt geschrieben. <br/>

Darauf aufsetzend wurden Funktionen definiert die mit "`isXXX()`" bzw "`hasXXXX()`" <br/>
anfangen. Die is-Funktionen prüfen auf eine Gerät, die has-Funktionen prüfen <br/>
auf eine Funktion (hat Bluetooth, hat Backlight, hat USB-Gerät XXXX:YYYY). <br/>

Dadurch ist das Anpassen, hier z.B. des grafischen Menüs, ziemlich einfach: <br/>

```text
    if (isDevA() || isDevE() || isDemo())
        addIcon(tr("Backlight"), ":/images/backlight.svg", SLOT(clickedBacklight()) );
```


### Daemons anpassen {#daemons-anpassen}

Auch Daemons müssen sich an die sehr unterschiedlicher Hardware anpassen. Dort <br/>
geht dies genauso einfach, hier am Beispiel des "`scannerd`": <br/>

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

Die folgenden Projekte verwenden (teils abgewandelt) das Combined Image: <br/>

-   [ Automatische Image-Erstellung ]({{< relref "mkimage" >}}) <br/>
-   [ Dynamischer Flash-Schutz ]({{< relref "dynamischer-flashschutz" >}}) <br/>
-   TODO(Artikel schreiben) Linux-Image auf Basis von i.MX&amp; RISC Prozessor für den Tagebau <br/>
-   TODO(Artikel schreiben) Linux Restore Stick <br/>
-   [ Hardware-Teststick für DLT-V83/DLT-V72 ]({{< relref "hwtester" >}}) <br/>
-   TODO(Artikel schreiben) Hardware-Teststick für DLT-V73 <br/>
-   TODO(Artikel schreiben) Aufräumen in Fukushima <br/>

