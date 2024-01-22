+++
title = "OpenEmbedded"
author = ["Holger Schurig"]
date = 2024-01-19
tags = ["linux", "kernel", "arm", "zaurus", "sa1110", "pxa320", "opie"]
categories = ["job"]
draft = false
+++

TODO <br/>

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Projekt-Info](#projekt-info)
- [Geschichte](#geschichte)
- [Bitbake](#bitbake)
- [BitKeeper](#bitkeeper)
- [Mein Ausstieg](#mein-ausstieg)
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

Idee: Chris Larson, Michael Lauer, ich <br/>

Umsetzung: (Programm) ich, (Träger-Verein) Michael Lauer, (Kommunikation) Chris <br/>
Larson. Später haben noch viele andere Leute mitgebracht, hervorheben mächte ich <br/>
Holger Freyther (der "`bitbake`" verbessert hat und Marcin Juskiecz, der viele, <br/>
viele Rezepte erstellt bzw. verbessert hat. <br/>

Nutzung: 2003 bis 2010, das Projekt dauert aber bis heute an <br/>

Implementatierung: Make, Bash, Python, BitKeeper (zunächst), dann Git, Bitbake-Recipes <br/>


## Geschichte {#geschichte}

Im Jahr 2003 gab es noch keine Smartphones. Aber ungefähr zu diesem Zeitpunkt tauchte <br/>
der Sharp Zaurus auf. Das war ein kleiner PDA mit Intel StrongARM SA1100 CPU. <br/>

{{< figure src="./sharp_zaurus.jpg" >}} <br/>

Auf diesem Bild, kopiert von <https://en.wikipedia.org/wiki/Sharp_Zaurus> (Lizenz <br/>
[CC BY-SA 3.0 Deed](https://creativecommons.org/licenses/by-sa/3.0/deed.en)) sieht man einen Zaurus, auf dem [OpenEmbedded](https://en.wikipedia.org/wiki/OpenEmbedded) und Opie (später <br/>
[OpenZaurus](https://de.wikipedia.org/wiki/OpenZaurus)) läuft. Opie war damals in Qt 2 geschieben --- was ich damals noch <br/>
nicht konnte --- und hatte z.B. Terminkalender, Adressbuch, TODO-Liste etc <br/>
integriert. <br/>

Michael und Chris beispielsweise hatten diese Geräte und wollten dafür Images <br/>
erstellen. <br/>

Ich selbst hatte aus beruflichen Gründen den Wunsch, Images für ARM-Geräte zu <br/>
erstellen. Mein damaliger Arbeitgeber hatte den "MNCI" auf Basis des PXA320 <br/>
entwickelt, und dafür mußte Software her --- und zwar kein Windows CE. <br/>

Wir trafen uns auf IRC und beratschlagten, wie man so ein Image bauen könnte. <br/>
Es müsste mit den diversen Zaurus-Hardware-Versionen (Collie, Poodle etc) <br/>
klarkommen, aber auch mit meinem Industriegerät. In der Firma setzte ich damals <br/>
Red Hat ein, privat hatte ich aber gerade mit Gentoo experimentiert. Und so kam <br/>
ich auf die Idee, das man "Rezepte" zum Bauen von Paketen haben sollte. Wer ganau <br/>
hinschaut wird merken, das sie an die "`.ebuild`" von gentoo erinnern. <br/>

Ein großer Unterschied zu Gentoo ist natürlich die Cross-Compilierung und daher <br/>
das "Staging"-Konzept. Um beispielsweise libpng für ARM cross-compilieren zu <br/>
können, muß die glibc ebenfalls für ARM vorliegen. Sie kann aber nicht da stehen, <br/>
wo meine normale glibc für meinen Linux-Entwicklungsrechner steht. Sondern muß davon <br/>
getrennt sein, eben im "Staging"-Bereich. <br/>

Was wir auch machen mußten: viele Buildsystem (beispielsweise GNU Autoconf) <br/>
erstellen zum Zeitpunkt von "`./configure`" viele kleine Testprogramme und <br/>
lassen diese dann laufen. So stellen sie z.B. fest wie lange ein Integer ist, <br/>
oder ob O_SYNC implementiert ist. Nur: wenn wir cross-compilieren, dann sind <br/>
diese Testprogramme ja in ARM-Maschinensprache. Mein Entwicklungsrechner war <br/>
aber i386. Also schlagen alle diese Tests fehl, "`./configure`" geht nicht. Und <br/>
qemu-user-static existierte noch nicht. Also mussten wir die diversen <br/>
Build-Systeme dazu überreden, von uns vorab erstellte Ergebnisse dieser Tests zu <br/>
nehmen statt selbst zu testen. <br/>


## Bitbake {#bitbake}

Diese Bau-Rezepte wurden von Bitbake ausgeführt. Die ersten 100-300 Commits <br/>
(weiss ich nicht mehr genau) stammen von mir. Ebenso das Design der Rezepte und <br/>
"`.bbclass`" Klassen. <br/>

Nachteilig von Bitbake damals war die lange Latenz beim Starten eines Build. So <br/>
wie ich die Rezepte organisiert hatte, mussten sie im Prinzip alle eingelesen werden <br/>
um einen Dependency-Graph aufzubauen. Und dieses Parsen war, auch wg. Python, nicht <br/>
das schnellste. Ich selbst hatte das Problem damals nicht gelöst, bis ca. 500 Rezepte <br/>
konnte man es auch noch aushalten. Aber als OpenEmbedded immer größer wurde, war es <br/>
ein großes Problem. Deswegen würde ich Holger Freyther ("zecke" im IRC) noch mit <br/>
aufnehmen: er hatte einen Cache des Graphen eingebaut. <br/>


## BitKeeper {#bitkeeper}

Wir hatten den Source damals in einem "distributed source code versioning <br/>
system" names [BitKeeper](https://en.wikipedia.org/wiki/Bitkeeper) gehalten. Das war sozusagen der Vorgänger und Ideengeber <br/>
zu Git --- und der letzte Schrei. Die Firma "BitMover Inc" hatte BitKeeper für <br/>
OpenSource-Projekte kostenlos gemacht. Auch der Linux-Kernel verwendete es. <br/>

Als dann aber das Verhältnis von "BitMover Inc" zur Kernel-Community sauer <br/>
wurde, hat Linus Torvalds "`git`" entwickelt, in die Linux-Kernel-Community <br/>
eingeführt. Und wir von OpenEmbedded sind nahezu zeitgleich umgestiegen. <br/>


## Mein Ausstieg {#mein-ausstieg}

Leider hat sich der "MNCI" nicht gut verkauft --- der Spediteur, für den wir den <br/>
MCNI entwickelt haben, meinte auf einmal "Also ich bin international, und ihr <br/>
seid eine kleine 30-Personen-Firma. Von euch kann ich das nicht kaufen". M&amp;N <br/>
konnte die Entwicklungskosten nicht refinanzieren und meldete Insolvenz an. <br/>

Damit hatte es sich für mich erübrigt, an OpenEmbedded weiterzuarbeiten --- <br/>
Interesse an PDAs hatte ich nämlich nicht. <br/>

Später habe ich für andere ARM-Platformen kein OpenEmbedded mehr genommen, <br/>
sondern mir direkt Debian ARM installiert. Das war um Größenordnungen schneller, <br/>
da ja keinerlei Sourcen mehr compiliert werden müssen. Ich spreche hier von <br/>
Minuten statt 16 Stunden um ein Image "from Scratch" neu zu bauen. <br/>

Aber das war ungefähr zu den Zeitpunkt, an dem Yocto entstand. Und so war die <br/>
Zukunft von OpenEmbedded gegeben, auch ohne mich. Das war noch vor Entwicklung <br/>
der "layers". <br/>


## Verwandte Projekte {#verwandte-projekte}

Die folgenden Projekte verwenden OpenEmbedded:: <br/>

-   TODO(Artikel schreiben) MNCI

