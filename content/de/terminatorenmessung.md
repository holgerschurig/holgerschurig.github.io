+++
title = "Terminatoren ausmessen"
topics = [ "Amateurfunk" ]
#keywords = HP8920, HP8920A, Terminator, Terminatoren, Reflektionsmesskopf, BX-066
tags = [ "HP8920", "Messen" ]
date = "2010-06-13"
+++

Eigentlich wollte ich mir mal den [BX-066]({{< relref "de/bx066.md" >}})
"Messtechnisch" mit dem [HP8920A]({{< relref "de/hp8920a.md" >}}) ansehen, z.B. die
Einfügedämpfung und die Richtschärfe bestimmen.

Dazu, dachte ich, betreibe ich den BX-066 erst mal offen, dann schließe
ich einen Terminator mit 50 Ohm an und schau ihn mir nochmals an. Dann
sehe ich ja, wieviel Leistung im BX-066 bleibt.

<!--more-->

In meiner Grabbelkiste habe ich 4 BNC-Endwiderstände mit 50 Ohm
gefunden:

<img src="terminatorenmessung.jpg" alt="50 Ohm Terminatoren" width="630" height="273" class="pure-img" />

Prima, dachte ich, da kann ich doch mal losmessen.

Sollte man meinen.

Jedoch zeigen meine vier Terminatoren ein sehr unterschiedliches
Verhalten, so daß die Messung dann eher zum Terminatoren-Vergleich
ausartete.

## Verhalten zwischen 1 und 51 MHz

<img src="terminatorenmessung_1.png" alt="Erster (linker) Terminator" width="513" height="259" class="pure-img" />

Der einzige Messwiederstand, der sich auch noch für 2 Mhz eignet.
Dafür ist er bei 7 MHz der schlechteste.

<img src="terminatorenmessung_2.png" alt="Zweiter Terminator" width="513" height="259" class="pure-img" />

Zwar nicht für weniger als 2 MHz geeignet, aber immerhin doch besser
als der vorherige Terminator.

<img src="terminatorenmessung_3.png" alt="Dritter (grüner) Terminator" width="513" height="259" class="pure-img" />

Nochmals deutlich besser, ein fast 10 dBm höheres "Return Loss".

<img src="terminatorenmessung_4.png" alt="Vierter (rechter) Terminator" width="513" height="259" class="pure-img" />

Hier der beste Terminator. Über eine weiten Bereich ein recht
lineares, recht tiefes Return Loss.


## Verhalten 2 bis 450 MHz

So, dann man schauen, wie sich die Terminatoren (bzw. der BX-044) bei
UKW verhalten. In den folgenden Messungen liegen übrigens 144 MHz bei
3,2 Kästchen in der x-Achse.

<img src="terminatorenmessung_5.png" alt="Erster (linker) Terminator" width="513" height="259" class="pure-img" />

<img src="terminatorenmessung_6.png" alt="Zweiter Terminator" width="513" height="259" class="pure-img" />

<img src="terminatorenmessung_7.png" alt="Dritter (grüner) Terminator" width="513" height="259" class="pure-img" />

<img src="terminatorenmessung_8.png" alt="Vierter (rechter) Terminator" width="513" height="259" class="pure-img" />

Nun, für UKW taugt entweder der (unmodifizierte) BX-066 Richtkoppler
nicht ... oder die Terminatoren.


## Fazit

Schon erstaunlich, wie unterschiedlich die Terminatoren sind.
Besonders der Unterschied zwischen dem ersten (ganz linken) und dem
letzten (ganz rechts) ist drastisch.

Ich habe mir den vierten Terminator markiert. Das ist nun mein
"Messwiderstand" für Kleinsignalleistungen und für KW. Aber nur
solange, bis ich mir was besseres baue :-)


Anhang: Umrechnung dBm nach VSWR
================================

Der [HP8920A]({{< relref "de/hp8920a.md" >}}) zeigt "nur" das "Return Loss" in dBm
an, kein dimensionsloses SWR-Verhältnis. Im "Application Handbook" ist
aber eine Übersetzungsliste:

| Return Loss | &nbsp;VSWR |
|------------:|-----------:|
| 5.0 dBm     | 3.6  |
| 10.0 dBm    | 1.9  |
| 15.0 dBm    | 1.4  |
| 20.0 dBm    | 1.2  |
| 25.0 dBm    | 1.12 |
| 30.0 dBm    | 1.07 |

&nbsp;
