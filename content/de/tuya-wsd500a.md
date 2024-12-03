+++
title = "Home-Assistant: Tuya Temperature Humidity Sensor"
author = ["Holger Schurig"]
date = 2024-12-03
tags = ["Heizkörper", "TRV", "Zigbee", "Moes", "BRT-100-TRV"]
categories = ["home-assistant"]
draft = false
+++

Hier geht es um den "Tuya Temperature Humidity Sensor"

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Einkauf](#einkauf)
- [Einbindung in Home-Assistant - problemlos!](#einbindung-in-home-assistant-problemlos)
- [Batterie - flexibel!](#batterie-flexibel)
- [Temperaturmesser --- gut!](#temperaturmesser-gut)
- [Luftfeuchtemesser -- gut!](#luftfeuchtemesser-gut)
- [Kaufempfehlung?](#kaufempfehlung)

</div>
<!--endtoc-->

{{< figure src="/ox-hugo/tuya-wsd500a.jpeg" >}}

Die Verpackung ist etwa 3.7 x 7.5 cm groß. Und der Sensor 2.5 x 7 cm.


## Einkauf {#einkauf}

Ich habe die Sensoren bei eBay (ich boykottiere Amazon!) gekauft. 2
Stück von diesen Sensoren für 23.99 EUR.

Der Verkäufer ist shady, nennt sich "vgaydagyg". Wahrscheinlich macht
er jedesmal einen neuen Buchstabensalat-Account, wenn es schlechte
Bewertungen gibt. Ich musste den Artikel oder den Verkäufer jedoch
nicht schlecht bewerten.

Gekauft habe ich die Sensoren mit eigenem Geld, nichts hier auf meiner
Home-Page ist gesponsort.

Der Verkäufer tituliert sie als "Tuya Smart Wifi/ ZigBee Temperature
Humidity Sensor Monitor for Alexa Google":

-   Tuya? Sie sind von "Aubess" gebranded und laufen ohne Tuya-App. In
    Zigbee2MQTT werden sie aber dennoch als "Tuya" angezeigt. Man
    braucht aber keine Tuya-App auf dem Smartphone, **keine Cloud**. Auch
    nicht für die Inbetriebnahme.
-   Smart? Nichts an den Sensoren selbst ist "smart" und das ist auch
    gut so!
-   Wifi?  Man sollte die Zigbee-Version kaufen
-   Alexa? Google? Wieso vergessen unsere chinesischen Freunde immer,
    das Home-Assistant so viel leistungsfähiger ist? Geht jedenfalls
    ohne Probleme mit HA.


## Einbindung in Home-Assistant - problemlos! {#einbindung-in-home-assistant-problemlos}

Das Gerät wird per Zigbee angebunden. Ich verwende nicht ZHA, sondern
Zigbee2MQTT und das hat den Thermostat **problemlos erkannt**.

Man muss nur auf der Unterseite mit einer Büroklammer für zwei, drei
Sekunden den Taster drücken.

Siehe auch: <https://www.zigbee2mqtt.io/devices/WSD500A.html>

In Zigbee2MQTT selbst gibt es keine Einstellungen, nur die Werte.

{{< figure src="/ox-hugo/wsd500a-zigbee2mqtt.png" >}}

... aber die sind **gut**!!!   Und die Entitäten, die dann automatisch
in Home-Assistant angelegt werden sind identisch (nur passen sie nicht
so schön auf eine Seite).


## Batterie - flexibel! {#batterie-flexibel}

Es werden 2 Batterien vom Typ "AAA" benötigt.

Ich habe aber ein NiMH Akkus eingelegt. Diese haben eine niederigere
Zellenspannung als Alkaline-Wegwerf-Batterien. Der Sensor funktioniert
damit einwandfrei. Allerdings startete die Batterie-Kapazitätsanzeige
bei 87% statt 100%. Aber damit kann ich leben.

Die Batteriekapazität wird in Prozent übertragen, mit einer
Schrittweite von ... keine Ahnung. Habe die Teile seit einem Monat und
sie zeigen konstant 87% an. Vielleicht sind die 1100 mAh des Akku
Overkill.

{{< figure src="/ox-hugo/wsd500a-batterie.png" >}}


## Temperaturmesser --- gut! {#temperaturmesser-gut}

Die Temperatur wird nur in Zehntel-Graden gemessen und prompt
übertragen.

Auf dem Bild sieht das recht wild aus ...

{{< figure src="/ox-hugo/wsd500a-temperatur.png" >}}

... aber in Wirklichkeit ist das gut. Ich nutze den Hobby-Raum gerade
nicht. Es gibt also keine Einflüsse durch mich. Im Prinzip sieht man
hier nur, wie die mechanische Regelung des Heizköpers-Termostats
arbeitet.

Und auch wenn das wie eine Achterbahn aussieht ... wir reden hier von
einer Temperaturdifferenz von lediglich 0.5 Kelvin.


## Luftfeuchtemesser -- gut! {#luftfeuchtemesser-gut}

Auch dies sieht gut aus. Die Luftfeuchte wird nicht nur in vollen
Werten übertragen, sondern abgestufter:

{{< figure src="/ox-hugo/wsd500a-luftfeuchte.png" >}}

Und da die relative Luftfeuchte direkt mit der Temperatur
zusammenhängt machen die Abstufungen auch Sinn.

Hier mal aus der Historie nach einem Stoßlüften:

{{< figure src="/ox-hugo/wsd500a-luftfeuchte_stosslüften.png" >}}

Hier ist nach dem Stoßlüften vermutlich Luftfeuchte vom Rest-Haus in
den Hobby-Raum gekommen. Dessen Tür war ja auf und ich habe eine
Gemüsesuppe gekocht.

Insgesamt habe ich derzeit 5 Sensoren installiert:

-   Hobbyraum (Keller, beheizt)
-   Lagerraum (Keller)
-   Waschraum (Keller)
-   Schlafzimmer (1. OG, beheizt)
-   ehem. Kinderzimmer (1. OG, beheizt)

Sie zeigen pro Stockwert / Heizstatus alle ähnliche Werte an. Und die
Werte erscheinen mir alle plausibel.


## Kaufempfehlung? {#kaufempfehlung}

Ein kräftiges **Ja**. Bisher die besten Sensoren für den Innenraum.
