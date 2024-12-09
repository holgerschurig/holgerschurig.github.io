+++
title = "Home-Assistant: Neo Steckdose WR10B"
author = ["Holger Schurig"]
date = 2024-12-03
tags = ["Steckdose", "Zigbee", "Nea", "WR10BH", "E1703"]
categories = ["home-assistant"]
draft = false
+++

Hier geht es um den Steckdose von mediarath.de, genannt "Neo WR10BH".

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Abmessungen](#abmessungen)
- [Einkauf](#einkauf)
- [Einbindung in Home-Assistant - problemlos!](#einbindung-in-home-assistant-problemlos)
- [Verbrauchsmessung - gut!](#verbrauchsmessung-gut)
- [Zigbee Mesh](#zigbee-mesh)
- [Kaufempfehlung?](#kaufempfehlung)

</div>
<!--endtoc-->


## Abmessungen {#abmessungen}

Der Durchmesser liegt bei knapp unter 5.9 cm. Der Teil, der aus der
Steckdose guckt ist ca. 5 cm groß.

{{< figure src="./wr10bh.jpeg" >}}


## Einkauf {#einkauf}

Ich habe die Steckdose bei mediarath.de gekauft, also normaler Kunde.
Ich bekomme keine Prozente --- überhaupt sind alle meine Artikel
selbstgekauft, nichts ist irgendwie gesponsort.

Übrigens: alle Zigbee-Artikel bei mediarath.de sind ausnahmslos mit
Home-Assistant getestet. U.u. flashen sie die Geräte um. Und teuer
sind sie auch nicht. Letztens hat "smartzeug" auf Youtube etwas
vorgestellt, Black-Friday-Aktion angeblich. Ein äquivalenter Artikel
war dann bei mediarath.de günstiger :-)


## Einbindung in Home-Assistant - problemlos! {#einbindung-in-home-assistant-problemlos}

Das Gerät wird per Zigbee angebunden. Ich habe den Skyconnect Stick
gekauft. Und am Anfang habe ich die Steckdosen --- problemlos! --- mit
ZHA betrieben.

Später bin ich dann auf Zigbee2MQTT umgestiegen und auch damit
funktionieren sie. Sie meldet sich dort als "Tuya TS011F_plug_1", geht
aber natürlich direkt. Man braucht keinerlei Tuya-App oder Tuya-Cloud.

{{< figure src="./wr10bh-zigbee2mqtt.png" >}}

Siehe auch: <https://www.zigbee2mqtt.io/devices/TS011F_plug_1.html>


## Verbrauchsmessung - gut! {#verbrauchsmessung-gut}

Sie ist zwar kleiner als die IKEA Tradfri E1603 ... aber kann dennoch mehr.

U.a. Verbrauchsmessung:

{{< figure src="./wr10bh-leistung.png" >}}


## Zigbee Mesh {#zigbee-mesh}

Sie funktioniert übrigens hervorragend, um das Zigbee-Mesh zu
vergrößern.


## Kaufempfehlung? {#kaufempfehlung}

Klares **Ja!** wenn man Leistungsmessung braucht.

Will man nur schalten, ist womöglich die aktuelle IKEA Trefakt besser,
weil günstiger.
