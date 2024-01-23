+++
title = "OpenEmbedded"
author = ["Holger Schurig"]
date = 2024-01-19
tags = ["arm", "embedded", "linux", "openembedded", "opie", "pxa320", "sa1110", "zaurus"]
categories = ["job"]
draft = false
+++

Ein kleiner Abriss, wie OpenEmbedded entstand, was mein Beitrag war und wieso
ich später eine bessere Lösung im Embedded-Linux-Bereich eingesetzt habe.

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Projekt-Info](#projekt-info)
- [Geschichte](#geschichte)
- [Bitbake](#bitbake)
- [Von BitKeeper zu Git](#von-bitkeeper-zu-git)
- [Mein Ausstieg](#mein-ausstieg)
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

Idee: Chris Larson, Michael Lauer, ich

Umsetzung: (Programm) ich, (Träger-Verein) Michael Lauer, (Kommunikation) Chris
Larson. Später haben noch viele andere Leute mitgebracht, hervorheben mächte ich
Holger Freyther (der "`bitbake`" verbessert hat und Marcin Juskiecz, der viele,
viele Rezepte erstellt bzw. verbessert hat.

Nutzung: 2003 bis 2010, das Projekt dauert aber bis heute an

Implementatierung: Make, Bash, Python, BitKeeper (zunächst), dann Git, Bitbake-Recipes


## Geschichte {#geschichte}

Im Jahr 2003 gab es noch keine Smartphones. Aber ungefähr zu diesem Zeitpunkt tauchte
der Sharp Zaurus auf. Das war ein kleiner PDA mit Intel StrongARM SA1100 CPU.

{{< figure src="./sharp_zaurus.jpg" >}}

Auf diesem Bild, kopiert von <https://en.wikipedia.org/wiki/Sharp_Zaurus> (Lizenz
[CC BY-SA 3.0 Deed](https://creativecommons.org/licenses/by-sa/3.0/deed.en)) sieht man einen Zaurus, auf dem [OpenEmbedded](https://en.wikipedia.org/wiki/OpenEmbedded) und Opie (später
[OpenZaurus](https://de.wikipedia.org/wiki/OpenZaurus)) läuft. Opie war damals in Qt 2 geschieben --- was ich damals noch
nicht konnte --- und hatte z.B. Terminkalender, Adressbuch, TODO-Liste etc
integriert.

Michael und Chris beispielsweise hatten diese Geräte und wollten dafür Images
erstellen.

Ich selbst hatte aus beruflichen Gründen den Wunsch, Images für ARM-Geräte zu
erstellen. Mein damaliger Arbeitgeber hatte den [ MNCI ]({{< relref "mnci" >}}) auf
Basis des PXA320 entwickelt, und dafür mußte Software her --- und zwar kein
Windows CE.

Wir trafen uns auf IRC und beratschlagten, wie man so ein Image bauen könnte.
Es müsste mit den diversen Zaurus-Hardware-Versionen (Collie, Poodle etc)
klarkommen, aber auch mit meinem Industriegerät. In der Firma setzte ich damals
Red Hat ein, privat hatte ich aber gerade mit Gentoo experimentiert. Und so kam
ich auf die Idee, das man "Rezepte" zum Bauen von Paketen haben sollte. Wer ganau
hinschaut wird merken, das sie an die "`.ebuild`" von gentoo erinnern.

Ein großer Unterschied zu Gentoo ist natürlich die Cross-Compilierung und daher
das "Staging"-Konzept. Um beispielsweise libpng für ARM cross-compilieren zu
können, muß die glibc ebenfalls für ARM vorliegen. Sie kann aber nicht da stehen,
wo meine normale glibc für meinen Linux-Entwicklungsrechner steht. Sondern muß davon
getrennt sein, eben im "Staging"-Bereich.

Was wir auch machen mußten: viele Buildsystem (beispielsweise GNU Autoconf)
erstellen zum Zeitpunkt von "`./configure`" viele kleine Testprogramme und
lassen diese dann laufen. So stellen sie z.B. fest wie lange ein Integer ist,
oder ob O_SYNC implementiert ist. Nur: wenn wir cross-compilieren, dann sind
diese Testprogramme ja in ARM-Maschinensprache. Mein Entwicklungsrechner war
aber i386. Also schlagen alle diese Tests fehl, "`./configure`" geht nicht. Und
qemu-user-static existierte noch nicht. Also mussten wir die diversen
Build-Systeme dazu überreden, von uns vorab erstellte Ergebnisse dieser Tests zu
nehmen statt selbst zu testen.


## Bitbake {#bitbake}

Diese Bau-Rezepte wurden von Bitbake ausgeführt. Die ersten 100-300 Commits
(weiss ich nicht mehr genau) stammen von mir. Ebenso das Design der Rezepte und
"`.bbclass`" Klassen.

Nachteilig von Bitbake damals war die lange Latenz beim Starten eines Build. So
wie ich die Rezepte organisiert hatte, mussten sie im Prinzip alle eingelesen werden
um einen Dependency-Graph aufzubauen. Und dieses Parsen war, auch wg. Python, nicht
das schnellste. Ich selbst hatte das Problem damals nicht gelöst, bis ca. 500 Rezepte
konnte man es auch noch aushalten. Aber als OpenEmbedded immer größer wurde, war es
ein großes Problem. Deswegen würde ich Holger Freyther ("zecke" im IRC) noch mit
aufnehmen: er hatte einen Cache des Graphen eingebaut.


## Von BitKeeper zu Git {#von-bitkeeper-zu-git}

Wir hatten den Source damals in einem "distributed source code versioning
system" names [BitKeeper](https://en.wikipedia.org/wiki/Bitkeeper) gehalten. Das war sozusagen der Vorgänger und Ideengeber
zu Git --- und der letzte Schrei. Die Firma "BitMover Inc" hatte BitKeeper für
OpenSource-Projekte kostenlos gemacht. Auch der Linux-Kernel verwendete es.

Als dann aber das Verhältnis von "BitMover Inc" zur Kernel-Community sauer
wurde, hat Linus Torvalds "`git`" entwickelt, in die Linux-Kernel-Community
eingeführt. Und wir von OpenEmbedded sind nahezu zeitgleich umgestiegen.


## Mein Ausstieg {#mein-ausstieg}

Leider hat sich der "MNCI" nicht gut verkauft --- der Spediteur, für den wir den
MCNI entwickelt haben, meinte auf einmal "Also ich bin international, und ihr
seid eine kleine 30-Personen-Firma. Von euch kann ich das nicht kaufen". M&amp;N
konnte die Entwicklungskosten nicht refinanzieren und meldete Insolvenz an.

Damit hatte es sich für mich erübrigt, an OpenEmbedded weiterzuarbeiten ---
Interesse an PDAs hatte ich nämlich nicht.

Später habe ich für andere ARM-Platformen kein OpenEmbedded mehr genommen,
sondern mir direkt Debian ARM installiert. Das war um Größenordnungen schneller,
da ja keinerlei Sourcen mehr compiliert werden müssen. Ich spreche hier von
Minuten statt 16 Stunden um ein Image "from Scratch" neu zu bauen.

Aber das war ungefähr zu den Zeitpunkt, an dem Yocto entstand. Und so war die
Zukunft von OpenEmbedded gesichert. Wenn ich mir heute Stellenanzeigen in
"Embedded" Bereich anschaue, wird OpenEmbedded sehr häufig erwähnt: das Projekt
"brummt".


## Verwandte Projekte {#verwandte-projekte}

Die folgenden Projekte verwenden OpenEmbedded:

-   [ MNCI: Handterminal mit ARM (Intel PXA320) ]({{< relref "mnci" >}})
-   TODO(Artikel schreiben) Linux-Image auf Basis von i.MX&amp; RISC Prozessor für den Tagebau
