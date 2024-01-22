+++
title = "Dynamischer Flash-Schutz"
author = ["Holger Schurig"]
date = 2024-01-17
tags = ["linux", "aufs", "chroot", "flash"]
categories = ["job"]
draft = false
+++

Hier geht es darum, wie man den Flash-Speicher vor Wear-Out schützen kann, <br/>
ohne die Usability allzu sehr einzuschränken. <br/>

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Projekt-Info](#projekt-info)
- [Warum muss Flash geschützt werden?](#warum-muss-flash-geschützt-werden)
- [Lösungsansätze](#lösungsansätze)
    - [Losungsansatz Windows](#losungsansatz-windows)
    - [Lösungsansatz Android](#lösungsansatz-android)
    - [Lösungsansatz "Combined Linux"](#lösungsansatz-combined-linux)
- [Flash-Schutz am Beispiel](#flash-schutz-am-beispiel)
    - [Lesevorgang](#lesevorgang)
    - [Schreibvorgang](#schreibvorgang)
    - [Flash ändern](#flash-ändern)
    - [Debian-Pakete installieren / chroot](#debian-pakete-installieren-chroot)
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

Idee &amp; Umsetzung: ich <br/>

Projektdauer: 2012 bis heute <br/>

Effizienzgewinn: <br/>

-   das Filesystem bleibt auf den Kundengeräten über Jahre intakt <br/>
-   hebt die Kundenzufriedenheit deutlich --- nichts ist frustiger als ein Kunde, <br/>
    bei dem die auf Accord arbeitenden Mitarbeiter Zwangspausen haben weil man <br/>
    erst die CFast-Karte wechseln muss <br/>
-   Ausbrechen aus dem Flash-Schutz jederzeit ohne Reboot möglich --- wenn man <br/>
    weiss, wie :-) <br/>


## Warum muss Flash geschützt werden? {#warum-muss-flash-geschützt-werden}

Flash hat generell eine begrenzte Anzahl von Schreibzyklen. [Wikipedia](https://de.wikipedia.org/wiki/Flash-Speicher#Vor-_und_Nachteile) <br/>
beispielsweise schreibt "Bei übermäßiger Nichtbenutzung und bei qualitativ <br/>
minderwertigen Flash-Datenträgern könnte der Verlust elektrischer Ladung in den <br/>
Transistoren Daten in Sektoren beschädigen.". <br/>

Was aber ist eine "übermäßige Nutzung"? Das kann bereits das Log-File sein, in <br/>
das z.B. Java-Programmierer geradezu verliebt sind. Jede ausgegebene Zeile <br/>
erzeugt diese Aktionen auf Filesystem-Ebene: <br/>

-   schreiben eines oder mehrere Datenblocks (wenn die Zeile eine Blockgrenze überschreitet) <br/>
-   Update des Directory-Eintrages (Filelänge, Zeitstempel letzter Zugriff) <br/>
-   u.U. Update des inode-Daten (wenn ein neuer Block alloziert werden muss) <br/>

Über 365 Tage mal 8 Stunden Schicht ... passiert da recht viel. <br/>


## Lösungsansätze {#lösungsansätze}


### Losungsansatz Windows {#losungsansatz-windows}

Windows selbst hatte damals keine Lösung. <br/>

Aber Windows Embedded hatte einen Modus, in dem man die Partition auf "read-only" setzen <br/>
konnte. Das bedeutete aber einen Reboot --- was unter Windows Embedded 7 eine Ewigkeit dauerte. <br/>
Auch mußte die Applikation damit klarkommen. <br/>

Auch Windows EWF bedingte (idealerweise), das die Anwendung sich dessen bewusst ist. <br/>

In der Praxis sorgte dies dafür, das man ohne lange Wartezeiten keine Änderungen am Image <br/>
machen konnte, noch nicht mal die IP-Adresse war zu ändern. <br/>


### Lösungsansatz Android {#lösungsansatz-android}

Unter Android gibt es viele, viele Partitionen. Oft über 20 oder 30. Einige <br/>
davon kann man als Systempartitionen ansehen: sie sind komplett read-only. Ein <br/>
Umschalten in den beschreibbaren Modus ist für Endkunden nicht vorgesehen -&gt; man <br/>
ist dem Hersteller ausgeliefert. <br/>

Netterweise gibt es auch Partitionen, die beschreibbar sind. Dort wird ein Großteil <br/>
(aber nicht alles!) der Systemkonfiguration wie IP-Adresse abgespeichert. <br/>

Insbesondere die Update-Situation ist hier jedoch anzukreiden, eine Kopie dieses <br/>
Verfahrens wird nicht empfohlen. <br/>


### Lösungsansatz "Combined Linux" {#lösungsansatz-combined-linux}

Unter Linux gibt es sog. "Union Filesystems". Früher nur [AUFS](https://aufs.sourceforge.net/) (Another Union <br/>
Filesystem), heute auch [UnionFS](https://unionfs.filesystems.org/). <br/>

Hierbei hat man zwei Partitionen, die übereinander gelegt werden. In die obere <br/>
Partition (das Flash) wird nie geschrieben, von dort wird nur gelesen. Darüber <br/>
gelegt ist eine RAM-Disk. Schreibvorgänge werden dorthin umgeleitet. Wird <br/>
gelesen, schaut AUFS zunächst in der RAM-Disk nach. Steht dort die Datei, <br/>
bekommt man sie auch. Steht sie dort noch nicht, wird sie aus dem Flash gelesen. <br/>
In der RAM-Disk passiert dabei nichts. <br/>


## Flash-Schutz am Beispiel {#flash-schutz-am-beispiel}


### Lesevorgang {#lesevorgang}

Nehmen wir mal ein Programm, welches den Nameserver wissen will --- unter Linux übernimmt <br/>
das normalerweise die GNU C Library, sie liest "`/etc/resolv.conf`". Was passiert bei einem <br/>
frisch gebooteten System? <br/>

Beim Flash ist ein Default-Nameserver hinterlegt: <br/>

| Ort      | Datei                   | Inhalt bei Lesen   |
|----------|-------------------------|--------------------|
| Flash    | /etc/resolv.conf        | nameserver 4.4.4.4 |
| RAM-Disk | &lt;existiert nicht&gt; | nameserver 4.4.4.4 |

Wenn nun ein Programm auf "`/etc/resolv.conf`" zugreift, bekommt es den <br/>
4.4.4.4er Nameserver. Denn in der RAM-Disk existiert kein Eintrag. <br/>


### Schreibvorgang {#schreibvorgang}

Nach dem Boot wird oft ein DHCP-Client gestartet. Er holt sich (u.A.) die <br/>
IP-Adresse und den Nameserver ab --- in diesem Beispiel eine Adresse aus dem <br/>
172.16er Netzwerk. Der Nameserver wird dann nach "`/etc/resolv.conf`" <br/>
geschrieben. <br/>

Der Zustand ist nun so: <br/>

| Ort      | Datei            | Inhalt bei Lesen      |
|----------|------------------|-----------------------|
| Flash    | /etc/resolv.conf | nameserver 4.4.4.4    |
| RAM-Disk | /etc/resolv.conf | nameserver 172.16.1.1 |

Wenn nun ein Programm auf "`/etc/resolv.conf`" zugreift, bekommt es den <br/>
172.16.1.1er Nameserver. <br/>

Das Flash wurde **nicht** geändert. Das bedeutet übrigens auch: wenn man nun das <br/>
Gerät aus- und wieder einschaltet (oder rebootet), dann sind sämtliche <br/>
Änderungen am Filesystem wieder vergessen. <br/>


### Flash ändern {#flash-ändern}

Bei dem bisher beschriebenem System könnte man den Nameserver im Flash nie <br/>
ändern. Das ist ein wenig suboptimal: wenn der Kunde von DHCP auf statische <br/>
IP-Adressen umstellen wollte, hätter er Pech. <br/>

Allerdings habe ich oben ein wenig geschummelt und --- der Didaktik wegen --- <br/>
ein Detail ausgelassen: das Flash ist direkt per "`/media/realroot`" zu erreichen. <br/>
Eigentlich müsste der Zustand nach dem Booten also so aussehen: <br/>

| Ort      | Datei                                   | Inhalt bei Lesen   |
|----------|-----------------------------------------|--------------------|
| Flash    | /media/realroot/etc/resolv.conf         | nameserver 4.4.4.4 |
| RAM-Disk | /etc/resolv.conf (existiert aber nicht) | nameserver 4.4.4.4 |

Das Dateisystem-Root "`/`" ist Flash(ro)+RAM-Disk(rw). <br/>

Das "echte Root" (des Flash-Speichers) ist read-write erreichbar über "`/media/realroot`". <br/>

Wenn wir nun auf statische IP-Adresse umstellen, ändern wir einfach statt <br/>
"`/etc/resolv.conf`" die Datei "`/media/realroot/etc/resolv.conf`": <br/>

| Ort      | Datei                                   | Inhalt bei Lesen         |
|----------|-----------------------------------------|--------------------------|
| Flash    | /media/realroot/etc/resolv.conf         | nameserver 192.168.1.200 |
| RAM-Disk | /etc/resolv.conf (existiert aber nicht) | nameserver 192.168.1.200 |

Dies wurde nun im Flash geändert, nicht in der RAM-Disk. Da dort aber kein <br/>
eigenes "`/etc/resolv.conf`" existiert, wird das vom Flash durchgereicht. <br/>


### Debian-Pakete installieren / chroot {#debian-pakete-installieren-chroot}

Man kann sogar im "echten" Root jederzeit Debian-Pakete installieren. Dafür müssen <br/>
wir einfach nur per "`chroot`" dort hineinwechseln: <br/>

```sh
chroot /media/realroot
```

Da aber "`dpkg`" bzw. "`apt-get`" Zugriff auf Linux-Devicenodes und <br/>
-Pseudodateien brauchen, führen wir einfach ein Bind-Mount durch: <br/>

```sh
mount -o bind /dev     /media/realroot/dev
mount -o bind /dev/pts /media/realroot/dev/pts
mount -o bind /sys     /media/realroot/sys
mount -o bind /proc    /media/realroot/proc
debian_chroot="REALROOT" chroot /media/realroot /bin/bash -i
umount /media/realroot/proc
umount /media/realroot/sys
umount /media/realroot/dev/pts
umount /media/realroot/dev
```

Ein Script names "`in_realroot`" erledigt das schnell und einfach :-) <br/>


## Verwandte Projekte {#verwandte-projekte}

Die folgenden Projekte verwenden den Flash-Schutz bzw. gehen auf ihn ein: <br/>

-   [ Combined-Linux: ein Image für viele Geräte ]({{< relref "combined-linux" >}}) <br/>
-   TODO(Artikel schreiben) GUI Konfiguration: config + configwriter <br/>
-   TODO(Artikel schreiben) Image-Verteilung mit SSDP-Agent <br/>
-   TODO(Artikel schreiben) Linux-Image auf Basis von i.MX&amp; RISC Prozessor für den Tagebau <br/>
-   TODO(Artikel schreiben) Linux Restore Stick <br/>
-   TODO(Artikel schreiben) Hardware-Teststick für DLT-V83/DLT-V72 <br/>
-   TODO(Artikel schreiben) Hardware-Teststick für DLT-V73 <br/>
-   TODO(Artikel schreiben) Aufräumen in Fukushima

