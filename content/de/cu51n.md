+++
title = "Schurig Universalzähler CU 51 N"
topics = [ "Elektronik" ]
tags = [ "CU51N", "Messen" ]
aliases = [ "amateurfunk/cu51n.html" ]
#linktitle: CU51N
#parent: Messgeräte
#keywords: CU51N, CU 51 N, Universalzähler, Frequenzmesser
#sitemap_changefreq: monthly
#order: 4
date = "2010-06-03"
#mtime: 2010-06-13
#change: Bild vom Zähler hinzu
+++

Wie ich zu einem Relikt gekommen bin :-)

<!--more-->

## Vergangenheit

Mein Vater war selbstständig. Seine Firma hieß "Schurig Elektronik"
und war zunächst in Ober-Ramstadt, später dann in Georgenhausen. Beide
Orte liegen in der Nähe von Frankfurt. Bedingt durch die Scheidung
meiner Eltern hatte ich allerdings wenig Kontakt zu meinen Vater. Ich
kannte ihn nur bis zu meinem dritten Lebensjahr, dann sahe ich ihn
lange Zeit nicht mehr. Als ich vierzehn Jahre alt war, war ich dann
nochmals ein Jahr bei ihm.

Damals, so 1981, war ich schon etwas an Elektronik
interessiert, aber hatte natürlich keine Ahnung. Naja, schon damals
konnte ich besser programmieren als löten :-)

Mein Vater unterstützte meine Ambitionen mit den programmierbaren
Taschenrechner TI-59.

In seiner Firma habe ich auch ab und an mitgeholfen, jedoch fast nur
bei mechanischen Dingen. Ich kann mich noch erinnern, Kabelbäume
auf Nagelbretter angelegt zu haben. Die habe ich dann mit Wachsfaden
abgebunden und herausgetrennt. Eingesetzt wurden die dann in diverse
Geräte (jedes hatte natürlich sein eigenes Nagelbrett). Eines der
Geräte war eben jener Universalzähler, um den es hier geht.

## Gegenwart

Vor vier Wochen sah ich dann einen der CU51N-Zähler bei e-Bay. Obwohl
wir in den Urlaub fuhren, bat ich ein Bietprogramm, doch während
meines Urlaubs mitzubieten. Den Anbieter fragte ich, ob er mit einer
verspäteten Bezahlung einverstanden wäre. War er. Und es kam
tatsächlich so, daß ich diesen alten Zähler ersteigert habe.

<img src="cu51n.jpg" alt="Schurig Frequenzzähler CU51N" width="630" height="213" class="pure-img" />

Soweit ich es noch im Kopf habe, ist das Gerät mit 74xxx TTL-ICs
diskret aufgebaut. Mein Vater war einer der ersten, die diese Chips in
Deutschland verwendet haben. Es kann Ereignisse zählen sowie
Frequenzen und Periodendauern messen.

Ich habe ihn mal an den Eichgeber meines Oszis angeschlossen, aber
nichts passiert.

Dann habe ich ihn mal den RF-Generator des [HP8920A]({{< ref
"hp8920a.md" >}}) angeschlossen. Und siehe da, die 0.2 Volt des
Oszi-Eichgebers waren für das alte Gerät einfach zu wenig (obwohl es
einen 1 / 0.1 Volt Eingangswahlschalter hat). Aber ab 0.5 bekam ich
ungefähre Werte, ab 0.7 stimmten die Frequenzen. Jedenfalls so
ziemlich, der Quarz dieses 25 Jahre alten Gerätes ist nicht mehr der
beste. Statt 10 MHz zeigt es beispielsweise 10,089 MHz an. Aber
immerhin. Die obere Grenzfrequenz des Zählers liegt bei 18 MHz. Das
mag heute nicht viel sein, aber damals wurden CPUs wie 6502 oder Z80
noch mit kHz oder max. 1 MHz betrieben.

Richtig schön, in solch alte Nixie-Röhren zu schauen :-)

Mein Vater hatte viele Fehler, aber ich habe ihn schon vor mehr als
einem Jahrzehnt vergeben. Nun diese greifbare Erinnerung seiner
Kreativität in den Händen zu haben, ist schon was :-)
