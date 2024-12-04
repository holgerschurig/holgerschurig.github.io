+++
title = "Home-Assistant: Aldi Wetterstation WS0306W"
author = ["Holger Schurig"]
date = 2024-12-03
tags = ["Wetterstation", "Temperatur", "Luftfeuchte", "rtl_433", "rtl-sdr", "Home-Assistant"]
categories = ["home-assistant"]
draft = false
+++

Hier geht es um eine Wetterstation "Krontaler Digitale Wetterstation".
Der Aufkleber von Aldi nennt sie auch "WS 0306-W". und wie man sie
(bzw. den externen Sensor) in Home-Assistant einbinden kann.

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Einkauf](#einkauf)
- [Anzeige - schlecht!](#anzeige-schlecht)
- [Uhrzeit](#uhrzeit)
- [Batterien](#batterien)
- [Anbindung an Home-Assistant](#anbindung-an-home-assistant)
    - [Proxmoxx](#proxmoxx)
    - [rtl_433 - nur zum Testen](#rtl-433-nur-zum-testen)
    - [rtl_433 Addon](#rtl-433-addon)
    - [Mosquitto Broker (MQTT Server)](#mosquitto-broker--mqtt-server)
    - [rtl_433 MQTT Auto Discovery - nicht aktivieren!](#rtl-433-mqtt-auto-discovery-nicht-aktivieren)
    - [Entities in Home-Assistant erzeugen](#entities-in-home-assistant-erzeugen)
- [Temperaturmesser - zu oft!](#temperaturmesser-zu-oft)
- [Feuchtigkeitsmesser - zu oft!](#feuchtigkeitsmesser-zu-oft)
- [Batteriekapazitätsmesser - unbrauchbar!](#batteriekapazitätsmesser-unbrauchbar)
- [Nutzung](#nutzung)
- [Kaufempfehlung?](#kaufempfehlung)

</div>
<!--endtoc-->


## Einkauf {#einkauf}

Ich habe die unten abgebildete Wetterstation selbst bei Aldi gekauft
(kein Artikel bei mir ist irgendwie gesponsert).

Das war im Frühjahr, wenn ich mich recht erinnere. Leider erinnere ich
mich auch nicht an den Preis, aber teuer war es nicht. Eine ähnliche
Wetterstation findet man aktuell für 13 EUR im Online-Shop von Aldi.

Hier sieht man die Basisstation und den zweiten, externen Sensor. Und
dieser machte das Gerät für Home-Assistant interessant!

{{< figure src="./ws0306w.jpeg" >}}


## Anzeige - schlecht! {#anzeige-schlecht}

Was ist der Unterschied zwischen dem vorherigen Bild und den nächsten?
Der Aufnahmewinkel.

Die Anzeige ist gut zu lesen, wenn man von schräg oben guckt.
Beispielsweise wenn man steht und die Wetterstation auf einem
Sideboard steht.

Man kann sie auch an die Wand hängen ... aber tut man das in
Augenhöhe, kann man die angezeigten Daten nur sehr schlecht sehen.
Eine Kontrast-Einstellung, die manche Geräte mit LCD-Display haben,
fehlt hier leider.

Mit einer nagelneuen Batterie ist die Anzeige besser --- aber nur für
3 Woche. Danach ist die Anzeige Monatelang mau:

{{< figure src="./ws0306w-mau.jpeg" >}}

Die Batterien innen sind übrigens gleich frisch wie die im
Batterietester steckende.

Außerdem sieht man unschwer, das das Display stark spiegelt. Die
Kamera verstärkt dies zwar, aber auch in echt ist das ebenfalls
deutlich.

An sich sind zu viele Elemente auf dem Display. Wenn man nur mal immer
wieder mal draufguckt, braucht es Zeit, um sich bei den vielen
angezeigten Dingen zu orientieren. Im Gegenuhrzeigersinn:

-   Datum (via DCF77)
-   Tag (via DCF77)
-   Uhrzeit (via DCF77)
-   Sonnenaufgang (errechnet)
-   Sonnenuntergang (errechnet)
-   Stadt
-   Mondphase (errechnet)
-   Temperatur / Luftfeuchte innen
-   irgendein Grinsegesicht
-   Temperatur / Luftfeuchte vom zweiten Sensor
-   Kanal des zweiten Sensors


## Uhrzeit {#uhrzeit}

In beiden Fotos ist Datum und Uhrzeit noch falsch. Für die Fotos habe
ich erst zwei nagelneue Batterien eingesetzt (um gescheiten Kontrast
hinzukriegen) und dann wieder die vorherigen (um den "Normalzustand"
zu dokumentieren).

Ich habe dann aber nicht die ein, zwei Minuten gewartet, bis (via
DCF77) **die Uhrzeit automatisch gesetzt** wird.

Auch bei Sommerzeit / Winterzeit musste ich nicht machen. Ein
deutlicher Vorteil z.B. gegen meinem Herd von "Bosch".


## Batterien {#batterien}

Es werden 2 AAA Batterien gebraucht.

Diese müssen für optimale Anzeige vollgeladen sein. Sonst wird die
Anzeige mau.

Vollgeladene NiMH-Akkus haben eine leicht geringere Zellenspannung als
Wegwerfbatterien. Auch mit ihnen sieht die Anzeige mau aus.


## Anbindung an Home-Assistant {#anbindung-an-home-assistant}


### Proxmoxx {#proxmoxx}

Der RTL-SDR Stick ist ein USB-Gerät. Da ich mein Home-Assistant unter
Proxmoxx auf einem Intel-NUC laufen lasse, muss ich die USB-Adresse
des Sticks erst noch in die Home-Assistant VM durchleiten.

Das geht unter Datacenter -&gt; proxmoxx -&gt; ha VM -&gt; Hardware -&gt; Add USB
Device -&gt; 0bda:2832

Danach muss man die VM einmal neu starten.


### rtl_433 - nur zum Testen {#rtl-433-nur-zum-testen}

Nun habe ich mal [rtl_433](https://github.com/merbanan/rtl_433) darauf angesetzt. Und siehe da, da kommt ja
was:

```text
$ rtl_433 -F log
rtl_433 version 24.10 (2024-10-30) inputs file rtl_tcp RTL-SDR SoapySDR
Reading conf from "/home/holger/.config/rtl_433/rtl_433.conf".
Detached kernel driver
Found Rafael Micro R820T tuner
SDR: Using device 0: Generic, RTL2832U, SN: 77771111153705700, "Generic RTL2832U"
Exact sample rate is: 250000.000414 Hz
[R82XX] PLL not locked!
Allocating 15 zero-copy buffers
c{"time" : "2024-12-03T12:07:29.766387+0100", "model" : "Nexus-TH", "id" : 23, "channel" : 1, "battery_ok" : 1, "temperature_C" : 23.100, "humidity" : 39}
```


### rtl_433 Addon {#rtl-433-addon}

Addons sind Docker-Container für Home-Assistants "HAOS" bzw. dessen
Supervisor.

Man findet das Addon auf
<https://github.com/pbkhrv/rtl_433-hass-addons/> --- dort ist auch die
Installation beschrieben.

Ich habe mir das aber viel einfacher gemacht. Ich habe nämlich meine
Konfigurationsdatei angelegt und dementsprechend auch keine
Konfigurationsdatei im Konfigurations-Screen vom rtl_433 Addon
eingegeben:

{{< figure src="./ws0306w-rtl-sdr-addon.png" >}}

Damit werden schon Daten das externen Senders empfangen. Man braucht
dann aber noch den ...


### Mosquitto Broker (MQTT Server) {#mosquitto-broker--mqtt-server}

Dieser wird gemäß
<https://github.com/home-assistant/addons/tree/master/mosquitto>
installiert --- wahrscheinlich hat man das aber sowieso schon, wenn
man Zigbee2MQTT verwendet.


### rtl_433 MQTT Auto Discovery - nicht aktivieren! {#rtl-433-mqtt-auto-discovery-nicht-aktivieren}

... sollte **nicht** installiert werden. Zumindest dann nicht, wenn man
nicht irgendwelche Ghost-Entities von vorbeifahrenden Autos in
Home-Assistant haben möchte.

Wenn ich beispielsweise mit dem [MQTT Explorer](https://mqtt-explorer.com/) installiere, dann sehe
kann ich in Home-Assistant in allen veröffentlichten Topics browsen:

{{< figure src="./ws0306w-mqtt-explorer.png" >}}

Man sieht dort jede Menge von Geräten. Nun könnte ich zwar rtl_433 via
Konfigurationsdatei beibringen, nur bestimmte Protokolle zu machen.
Ich mag aber diese Liste von erkannten Geräten -- zumindest in
Mosquitto.


### Entities in Home-Assistant erzeugen {#entities-in-home-assistant-erzeugen}

Aber wie gelangt dann das "richtige" Topic nach Home-Assistant?  Mit
diesem Eintrag in `configuration.yaml`:

```text
homeassistant:
  packages: !include_dir_named packages
```

und einer Datei =packages/device_temphum_nexus_th1.yaml:

```text
# https://www.home-assistant.io/integrations/sensor.mqtt/
# https://www.home-assistant.io/integrations/binary_sensor.mqtt/
# https://pictogrammers.com/library/mdi/
mqtt:
  - sensor:
    - name: "Nexus TH1 Temperatur"
      state_topic: "rtl_433/9b13b3f4-rtl433/devices/Nexus-TH/1/23/temperature_C"
      unit_of_measurement: "°C"
      payload_available: "online"
      payload_not_available: "offline"
    - name: "Nexus TH1 Luftfeuchte"
      state_topic: "rtl_433/9b13b3f4-rtl433/devices/Nexus-TH/1/23/humidity"
      unit_of_measurement: "%"
      icon: "mdi:water-percent"
    - name: "Nexus TH1 Batterie:"
      state_topic: "rtl_433/9b13b3f4-rtl433/devices/Nexus-TH/1/23/battery_ok"
      icon: "mdi:battery"
```

Dies "per Hand" zu machen hat noch einen zweiten wichtigen Vorteil:
beim Batteriewechsel des externen Sensors ändert sich dessen Adresse.
Es wird dann nicht mehr "9b13b3f4-rtl433" veröffentlicht, sondern mit
einem anderen Hexwert.

Dadurch würde bei einer Auto-Erkennung die Entität in Home-Assistant
sich ändern.

History-Daten und Automationen wären kaputt.

Mit meiner Lösung sehe ich im MQTT-Explorer das neue Topic, passe die
YAML-Datei an und lade diese dann neu.


## Temperaturmesser - zu oft! {#temperaturmesser-zu-oft}

Ich beurteile hier mal nur die Temperaturanzeige des externen Sensors.
Die Wetterstation selbst sendet ja nicht!

{{< figure src="./ws0306w-temperatur.png" >}}

Der externe Sensor sendet als nicht nur volle Wärmegrade, sondern
abgestuft auf 0.1 °C. Allerdings hat er wenig (oder keine?) Hysterese
einprogrammiert, er sendet also u.U. sehr kurz hintereinander 22.1,
22.0, 22.1, 22.0, 22.1 --- das wird nicht so gut für die
Batterielaufzeit sein.

Im Vergleich mit anderen Thermometern erscheinen die Werte genau.


## Feuchtigkeitsmesser - zu oft! {#feuchtigkeitsmesser-zu-oft}

{{< figure src="./ws0306w-luftfeuchte.png" >}}

Hier wird in vollen Schritten übertragen, was vollkommen in Ordnung
ist.

Aber auch hier werden oft sehr kurz hintereinander Updates geschickt,
ohne Hysterese. Das könnte man besser machen!


## Batteriekapazitätsmesser - unbrauchbar! {#batteriekapazitätsmesser-unbrauchbar}

Diese ist **total unbrauchbar**. Sie kennt nur "battery_ok: 1". Also
100%.

Auch mit ziemlich leeren Batterien aus der Grabbelkiste habe ich kein
"battery_ok: 0" hinbekommen.

{{< figure src="./ws0306w-batterie.png" >}}

Ich ziehe Angaben zwischen 0 und 100% da deutlich vor. Sogar wenn die
Prozentangabe bei NiMH-Akkus nicht stimmen sollte.


## Nutzung {#nutzung}

Ich nutze

-   die Daten dieses Sensors
-   zusammen mit einem Außensensor
-   und dem HACS-Plugin "Thermal Comfort"

zur Entscheidung "Lüften oder nicht?". Das HACS-Plugin erlaubt es
recht einfach, aus Temperatur + relativer Luftfeuchtigkeit die
absolute Luftfeuchtigkeit bzw. den Taupunkt zu berechnen. Und wenn man
diese beiden für innen und außen berechneten Werte vergleicht, kann
man sehr gut feststellen, ob man sich mit Lüften Feuchtigkeit ins Haus
holen würde.


## Kaufempfehlung? {#kaufempfehlung}

Wenn man spielen will: ja

Wenn man eine Anzeige auch ohne Home-Assistant haben will und mit dem
schlechtem Display leben kann: ja

Wenn man noch keinen RTL-SDR Stick hat: nein

Stattdessen besser den Zigbee [ Tuya Temperature Humidity Sensor ]({{< relref "tuya-wsd500a" >}})
nutzen.
