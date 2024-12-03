+++
title = "Home-Assistant: IKEA Steckdose Tradfri E1703"
author = ["Holger Schurig"]
date = 2024-12-03
tags = ["Steckdose", "Zigbee", "Ikea", "Tradfri", "E1703"]
categories = ["home-assistant"]
draft = false
+++

Hier geht es um den IKEA Steckdose "Tradfri" E1703.

morek

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Abmessungen - zu groß!](#abmessungen-zu-groß)
- [Einkauf](#einkauf)
- [Einbindung in Home-Assistant - problemlos!](#einbindung-in-home-assistant-problemlos)
- [Schaltverhalten - gut!](#schaltverhalten-gut)
- [Verbrauchsmessung - fehlt!](#verbrauchsmessung-fehlt)
- [Zigbee Mesh](#zigbee-mesh)
- [Kaufempfehlung?](#kaufempfehlung)

</div>
<!--endtoc-->


## Abmessungen - zu groß! {#abmessungen-zu-groß}

Die Steckdose ist ein Koloss:

{{< figure src="/ox-hugo/e1703_unten.jpeg" >}}

Sie ist 5 x 10 cm (breit x lang). Wer sie in eine Mehrfachsteckdose
reinsteckt hat --- der hat links und rechts von ihr ein Problem. Oder,
je nach Lage der Steckdosenlöcher gleich mehrere Dosen abgedeckt.

{{< figure src="/ox-hugo/e1703.jpeg" >}}

Der Teil, der aus der Steckdose guckt, ist auch fast 3.5cm hoch.


## Einkauf {#einkauf}

Ich habe drei dieser Zigbee-Steckdosen bei IKEA in Frankfurt selbst
gekauft. Den Preis habe ich vergessen, so um die 14 Euro glaube ich.

Es waren meine ersten Zigbee-Geräte :-)


## Einbindung in Home-Assistant - problemlos! {#einbindung-in-home-assistant-problemlos}

Das Gerät wird per Zigbee angebunden. Ich habe den Skyconnect Stick
gekauft. Und am Anfang habe ich die Steckdosen --- problemlos! --- mit
ZHA betrieben.

Später bin ich dann auf Zigbee2MQTT umgestiegen und auch damit
funktionieren sie.

{{< figure src="/ox-hugo/e1703-zigbee2mqtt.png" >}}

Siehe auch: <https://www.zigbee2mqtt.io/devices/E1603_E1702_E1708.html>


## Schaltverhalten - gut! {#schaltverhalten-gut}

Sie schaltet prompt und zuverlässig.

Die 3840 Watt, die sie kann, habe ich nie ausgenutzt. Sie würden aber
auch für einen typischen Heizlüfter reichen, die haben ja i.d.R.
2000 Watt.


## Verbrauchsmessung - fehlt! {#verbrauchsmessung-fehlt}

Dafür, das die Steckdose so groß ist hat sie doch sicherlich eine
Verbrauchsmessung eingebaut?

Nein, denkste, gibts nich!


## Zigbee Mesh {#zigbee-mesh}

Sie funktioniert übrigens hervorragend, um das Zigbee-Mesh zu
vergrößern.

{{< figure src="/ox-hugo/e1703-mesh.png" >}}


## Kaufempfehlung? {#kaufempfehlung}

Das erübrigt sich, da dieser Typ nicht mehr verkauft wird. IKEA hat
nun eine kleinere Steckdose namens TREFAKT im Angebot, derzeit für 12
EUR. Aber die kenne ich nicht.

Wäre diese E1603 noch kaufbar, würde ich klar **Nein!** sagen.

Übrigens ... wer Leistungsmessung braucht, sollte die im Artikel
[ Home-Assistant: Neo Steckdose WR10B ]({{< relref "" >}}) beschriebene
Steckdose ins Auge fassen.
