+++
title = "Dynamischer Flash-Schutz"
author = ["Holger Schurig"]
date = 2024-01-17
tags = ["aufs", "chroot", "flash", "linux"]
categories = ["job"]
draft = false
+++

Hier geht es darum, wie man den Flash-Speicher vor Wear-Out schützen kann,
ohne die Usability allzu sehr einzuschränken.

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

In Beiträgen der Kategorie [Job](/categories/job/) trage ich Projekte zusammen, die ich im Rahmen
meiner beruflichen Karriere federführend durchgeführt habe. Ich gehe dabei mit
Absicht nicht allzusehr auf Details an: die Interessen meiner Arbeitgeber sollen
ja nicht berührt werden.

</div>


## Projekt-Info {#projekt-info}

Idee &amp; Umsetzung: ich

Projektdauer: 2012 bis heute

Effizienzgewinn:

-   das Filesystem bleibt auf den Kundengeräten über Jahre intakt
-   hebt die Kundenzufriedenheit deutlich --- nichts ist frustiger als ein Kunde,
    bei dem die auf Accord arbeitenden Mitarbeiter Zwangspausen haben weil man
    erst die CFast-Karte wechseln muss
-   Ausbrechen aus dem Flash-Schutz jederzeit ohne Reboot möglich --- wenn man
    weiss, wie :-)


## Warum muss Flash geschützt werden? {#warum-muss-flash-geschützt-werden}

Flash hat generell eine begrenzte Anzahl von Schreibzyklen. [Wikipedia](https://de.wikipedia.org/wiki/Flash-Speicher#Vor-_und_Nachteile)
beispielsweise schreibt "Bei übermäßiger Nichtbenutzung und bei qualitativ
minderwertigen Flash-Datenträgern könnte der Verlust elektrischer Ladung in den
Transistoren Daten in Sektoren beschädigen.".

Was aber ist eine "übermäßige Nutzung"? Das kann bereits das Log-File sein, in
das z.B. Java-Programmierer geradezu verliebt sind. Jede ausgegebene Zeile
erzeugt diese Aktionen auf Filesystem-Ebene:

-   schreiben eines oder mehrere Datenblocks (wenn die Zeile eine Blockgrenze überschreitet)
-   Update des Directory-Eintrages (Filelänge, Zeitstempel letzter Zugriff)
-   u.U. Update des inode-Daten (wenn ein neuer Block alloziert werden muss)

Über 365 Tage mal 8 Stunden Schicht ... passiert da recht viel.


## Lösungsansätze {#lösungsansätze}


### Losungsansatz Windows {#losungsansatz-windows}

Windows selbst hatte damals keine Lösung.

Aber Windows Embedded hatte einen Modus, in dem man die Partition auf "read-only" setzen
konnte. Das bedeutete aber einen Reboot --- was unter Windows Embedded 7 eine Ewigkeit dauerte.
Auch mußte die Applikation damit klarkommen.

Auch Windows EWF bedingte (idealerweise), das die Anwendung sich dessen bewusst ist.

In der Praxis sorgte dies dafür, das man ohne lange Wartezeiten keine Änderungen am Image
machen konnte, noch nicht mal die IP-Adresse war zu ändern.


### Lösungsansatz Android {#lösungsansatz-android}

Unter Android gibt es viele, viele Partitionen. Oft über 20 oder 30. Einige
davon kann man als Systempartitionen ansehen: sie sind komplett read-only. Ein
Umschalten in den beschreibbaren Modus ist für Endkunden nicht vorgesehen -&gt; man
ist dem Hersteller ausgeliefert.

Netterweise gibt es auch Partitionen, die beschreibbar sind. Dort wird ein Großteil
(aber nicht alles!) der Systemkonfiguration wie IP-Adresse abgespeichert.

Insbesondere die Update-Situation ist hier jedoch anzukreiden, eine Kopie dieses
Verfahrens wird nicht empfohlen.


### Lösungsansatz "Combined Linux" {#lösungsansatz-combined-linux}

Unter Linux gibt es sog. "Union Filesystems". Früher nur [AUFS](https://aufs.sourceforge.net/) (Another Union
Filesystem), heute auch [UnionFS](https://unionfs.filesystems.org/).

Hierbei hat man zwei Partitionen, die übereinander gelegt werden. In die obere
Partition (das Flash) wird nie geschrieben, von dort wird nur gelesen. Darüber
gelegt ist eine RAM-Disk. Schreibvorgänge werden dorthin umgeleitet. Wird
gelesen, schaut AUFS zunächst in der RAM-Disk nach. Steht dort die Datei,
bekommt man sie auch. Steht sie dort noch nicht, wird sie aus dem Flash gelesen.
In der RAM-Disk passiert dabei nichts.


## Flash-Schutz am Beispiel {#flash-schutz-am-beispiel}


### Lesevorgang {#lesevorgang}

Nehmen wir mal ein Programm, welches den Nameserver wissen will --- unter Linux übernimmt
das normalerweise die GNU C Library, sie liest "`/etc/resolv.conf`". Was passiert bei einem
frisch gebooteten System?

Beim Flash ist ein Default-Nameserver hinterlegt:

| Ort      | Datei                   | Inhalt bei Lesen   |
|----------|-------------------------|--------------------|
| Flash    | /etc/resolv.conf        | nameserver 4.4.4.4 |
| RAM-Disk | &lt;existiert nicht&gt; | nameserver 4.4.4.4 |

Wenn nun ein Programm auf "`/etc/resolv.conf`" zugreift, bekommt es den
4.4.4.4er Nameserver. Denn in der RAM-Disk existiert kein Eintrag.


### Schreibvorgang {#schreibvorgang}

Nach dem Boot wird oft ein DHCP-Client gestartet. Er holt sich (u.A.) die
IP-Adresse und den Nameserver ab --- in diesem Beispiel eine Adresse aus dem
172.16er Netzwerk. Der Nameserver wird dann nach "`/etc/resolv.conf`"
geschrieben.

Der Zustand ist nun so:

| Ort      | Datei            | Inhalt bei Lesen      |
|----------|------------------|-----------------------|
| Flash    | /etc/resolv.conf | nameserver 4.4.4.4    |
| RAM-Disk | /etc/resolv.conf | nameserver 172.16.1.1 |

Wenn nun ein Programm auf "`/etc/resolv.conf`" zugreift, bekommt es den
172.16.1.1er Nameserver.

Das Flash wurde **nicht** geändert. Das bedeutet übrigens auch: wenn man nun das
Gerät aus- und wieder einschaltet (oder rebootet), dann sind sämtliche
Änderungen am Filesystem wieder vergessen.


### Flash ändern {#flash-ändern}

Bei dem bisher beschriebenem System könnte man den Nameserver im Flash nie
ändern. Das ist ein wenig suboptimal: wenn der Kunde von DHCP auf statische
IP-Adressen umstellen wollte, hätter er Pech.

Allerdings habe ich oben ein wenig geschummelt und --- der Didaktik wegen ---
ein Detail ausgelassen: das Flash ist direkt per "`/media/realroot`" zu erreichen.
Eigentlich müsste der Zustand nach dem Booten also so aussehen:

| Ort      | Datei                                   | Inhalt bei Lesen   |
|----------|-----------------------------------------|--------------------|
| Flash    | /media/realroot/etc/resolv.conf         | nameserver 4.4.4.4 |
| RAM-Disk | /etc/resolv.conf (existiert aber nicht) | nameserver 4.4.4.4 |

Das Dateisystem-Root "`/`" ist Flash(ro)+RAM-Disk(rw).

Das "echte Root" (des Flash-Speichers) ist read-write erreichbar über "`/media/realroot`".

Wenn wir nun auf statische IP-Adresse umstellen, ändern wir einfach statt
"`/etc/resolv.conf`" die Datei "`/media/realroot/etc/resolv.conf`":

| Ort      | Datei                                   | Inhalt bei Lesen         |
|----------|-----------------------------------------|--------------------------|
| Flash    | /media/realroot/etc/resolv.conf         | nameserver 192.168.1.200 |
| RAM-Disk | /etc/resolv.conf (existiert aber nicht) | nameserver 192.168.1.200 |

Dies wurde nun im Flash geändert, nicht in der RAM-Disk. Da dort aber kein
eigenes "`/etc/resolv.conf`" existiert, wird das vom Flash durchgereicht.


### Debian-Pakete installieren / chroot {#debian-pakete-installieren-chroot}

Man kann sogar im "echten" Root jederzeit Debian-Pakete installieren. Dafür müssen
wir einfach nur per "`chroot`" dort hineinwechseln:

```sh
chroot /media/realroot
```

Da aber "`dpkg`" bzw. "`apt-get`" Zugriff auf Linux-Devicenodes und
-Pseudodateien brauchen, führen wir einfach ein Bind-Mount durch:

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

Ein Script names "`in_realroot`" erledigt das schnell und einfach :-)


## Verwandte Projekte {#verwandte-projekte}

Die folgenden Projekte verwenden den Flash-Schutz bzw. gehen auf ihn ein:

-   [ Combined-Linux: ein Image für viele Geräte ]({{< relref "combined-linux" >}})
-   TODO(Artikel schreiben) GUI Konfiguration: config + configwriter
-   TODO(Artikel schreiben) Image-Verteilung mit SSDP-Agent
-   TODO(Artikel schreiben) Linux-Image auf Basis von i.MX&amp; RISC Prozessor für den Tagebau
-   TODO(Artikel schreiben) Linux Restore Stick
-   TODO(Artikel schreiben) Hardware-Teststick für DLT-V83/DLT-V72
-   TODO(Artikel schreiben) Hardware-Teststick für DLT-V73
-   TODO(Artikel schreiben) Aufräumen in Fukushima
