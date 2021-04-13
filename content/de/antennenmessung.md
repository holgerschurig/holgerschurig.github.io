+++
title = "Reflektionsmessung an Antenne Maldol EX-104"
topics = [ "Amateurfunk" ]
#keywords = HP8920, HP8920A, SWR, Reflektionsmessung, Maldal EX-104
tags = [ "HP8920", "BX-066", "Messen" ]
date = "2010-06-13"
aliases = [ "amateurfunk/antennenmessung.html" ]
+++

Laborbucheintrag: wie man mit einem Spektrum-Analyzer eine Antenne ausmisst.

<!--more-->

## Referenz

 1. HP8920 Application Handbook, Kapitel "Antenna Return Loss
    (VSWR) Measurement & Tuning

## Material

 1. [HP8920A]({{< relref "hp8920a.md" >}})
 2. Mobilantenne "Maldol EX-104". Diese Antenne habe ich von DH6GRM
    geliehen bekommen
 4. [BX-066]({{< relref "bx066.md" >}}) von Funkamateur/Box73
 3. diverse Konverter von N- auf BNC, um die Antenne ans Reflektometer
    anzuschließen
 5. ein kurzes RG58 C/U Kabel mit BNC-Steckern

<img src="antennenmessung.jpg" alt="Maldol EX-104 an HP 8920A" width="630" height="473" class="pure-img" />

PS: auf den Bild verwende ich noch "RF In/Out" statt "Ant in", aber
das habe ich dann für die folgende Messung geändert.

Grundeinstellung
================

Ich gehe hier stur so vor, wie es im "HP8920 Application Handbook" steht:

 1. Richtkoppler an "Duplex out" sowie mit BNC-Kabel an "Ant in"
    anschließen
 2. HP8920A einschalten
 3. In Bildschirm Spektrum-Analysator" gehen
 4. Center-Frequenz 300 MHz und Span 320 MHz eingeben (damit geht der
    angezeigte Bereich von 140 - 460 MHz)
 5. Referenz-Level auf 0 dBm
 6. In Untermenu "RF Generator" gehen
 7. "Tracking Generator" auswählen
 8. "Amplitute" auf 0 dBm
 9. Am Reflektionsmesskopf den Ausgang "Load" offen lassen

Jetzt bekomme ich dieses Bild:

<img src="antennenmessung_1.png" alt="Vor der Normalisierung" width="513" height="259" class="pure-img" />


Normalisieren
=============

Nun muß ich das "wegrechnen" lassen:

 1. Untermenü "Auxiliary" wählen
 2. bei "Normalize" auf "Save B" drücken
 3. ebenda nun "A-B" auswählen

Und schon habe ich eine ebene Linie und es steht "Normalized" rechts
oben:

<img src="antennenmessung_2.png" alt="Korrekt normalisiert" width="513" height="259" class="pure-img" />

Messen
======

Nun wird die Antenne angeschlossen. Nach etwa zwei Sekunden erscheint
dieses Bild:

<img src="antennenmessung_3.png" alt="Reflexionsmessung" width="513" height="259" class="pure-img" />

... welches ziemlich nach Hausnummern aussieht. Diese Antenne scheint
sich für 171 MHz zu eignen. Was könnte da schief gelaufen sein ?!?!

 * vielleicht funktioniert der Reflektionsmesskopf nicht bei dieser
   hohen Frequenz?
 * die Mobilantenne hat keinen gescheiten Untergrund, es ist ja
   gedacht, das sie auf ein Autodach "geklebt" wird (Magnetfuss ist
   eingebaut)
 * ich sitze viel zu nah ander Antenne. Jede Bewegung von mir ist
   "sichtbar". Krass wird es, wenn ich die Antenne mit der Hand an der
   (mit Plastik eingehausten) Verlängerungsspule anfasse und hochhebe:

<img src="antennenmessung_4.png" alt="stark beeinflusste Reflexionsmessung" width="513" height="259" class="pure-img" />

Fazit
=====

Vertikalantennen ohne Gegengewicht sind kein Anfängerspielzeug :-)
