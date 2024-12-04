+++
title = "Home-Assistant: Bresser Außensensor"
author = ["Holger Schurig"]
date = 2024-12-03
tags = ["Bresser", "Temperatur", "Luftfeuchte", "rtl_433", "rtl-sdr", "Home-Assistant"]
categories = ["home-assistant"]
draft = false
+++

Hier geht es um eine 433 MHz Sensor für Temperatur / Luftfeuchte
"BRESSER 8-Kanal-Thermo-Hygro-Sensor"

... und auch darum, wie man einen Außensensor durch einen
Template-Sensor in Zusammenarbeit mit dem Home-Assistant "Weather
Forecast" ersetzen kann :-)

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Einkauf](#einkauf)
- [Batterien](#batterien)
- [Anbindung an Home-Assistant](#anbindung-an-home-assistant)
- [Temperaturmesser](#temperaturmesser)
- [Feuchtigkeitsmesser](#feuchtigkeitsmesser)
    - [Eigentlich ...](#eigentlich-dot-dot-dot)
    - [Jedoch!](#jedoch)
    - [Stattdessen](#stattdessen)
- [Batteriekapazitätsmesser - unbrauchbar!](#batteriekapazitätsmesser-unbrauchbar)
- [Nutzung](#nutzung)
- [Kaufempfehlung?](#kaufempfehlung)

</div>
<!--endtoc-->


## Einkauf {#einkauf}

Ich habe ihn auf deren Webseite gekauft, weil er dort als
"Außensensor" beworben wurde. Der Preis war so um die 30€. Ich habe
das selbst bezahlt. Auf dieser Webseite gibt es keine gesponserten
Artikel.

Das ist allerdings nicht billig ...verglichen mit Innensensoren. Da
Bresser einen Sitz in Deutschland hat habe ich mir erhofft, keine
"Chinaware" zu bekommen. Unten im Fazit steht, ob sich das erfüllt hat.

{{< figure src="./bresser-eurochon.jpeg" >}}

(hier sieht man sie unter dem Dach des Gartenhäuschens aufgehängt)


## Batterien {#batterien}

Es werden 2 AAA Batterien gebraucht.

Finde ich besser als Spezialbatterien. Oder LiIon-Akkus, solange die
eine relativ hohe Brandgefahr haben.


## Anbindung an Home-Assistant {#anbindung-an-home-assistant}

Man bindet diesen Sensor genauso ein wie den externen Sensor aus dem
Artikel [ Aldi Wetterstation ]({{< relref "aldi-wetterstation-ws0306w" >}}).

Deswegen hier nur die YAML-Datei `packages/bresser-eurochron.yaml`:

```text
# https://www.home-assistant.io/integrations/sensor.mqtt/
# https://www.home-assistant.io/integrations/binary_sensor.mqtt/
# https://pictogrammers.com/library/mdi/
mqtt:
  - sensor:
    - name: "Eurochron EFTH800 Temperatur"
      state_topic: "rtl_433/9b13b3f4-rtl433/devices/Eurochron-EFTH800/1/1196/temperature_C"
      unit_of_measurement: "°C"
      payload_available: "online"
      payload_not_available: "offline"
    - name: "Eurochron EFTH800 Luftfeuchte"
      state_topic: "rtl_433/9b13b3f4-rtl433/devices/Eurochron-EFTH800/1/1196/humidity"
      unit_of_measurement: "%"
      icon: "mdi:water-percent"
    - name: "Eurochron EFTH800 Batterie:"
      state_topic: "rtl_433/9b13b3f4-rtl433/devices/Eurochron-EFTH800/1/1196/battery_ok"
      icon: "mdi:battery"
```


## Temperaturmesser {#temperaturmesser}

{{< figure src="./bresser-temperatur.png" >}}

Das sieht gut aus. Nicht nur volle Grad, auch Zwischenwerte. Und die
Werte werden zwar prompt, aber auch nicht allzuoft geschickt.


## Feuchtigkeitsmesser {#feuchtigkeitsmesser}


### Eigentlich ... {#eigentlich-dot-dot-dot}

{{< figure src="./bresser-luftfeuchte.png" >}}

Das sieht doch gut aus ... nicht nur volle Grad, auch Zwischenwerte. Und die
Werte werden zwar prompt, aber auch nicht allzu oft geschickt.


### Jedoch! {#jedoch}

**Oder doch nicht??!?** Die Werte waren nämlich gut ... bis ein wir
einen Sturm hatten und der Sturm den Außensensor vom Nagel geblasen
hat. Bis ich es anhand der seltsamen Luftfeuchtigkeit merkte,
vergingen zwei Tage.

Soviel zum Thema "\*Außen\*sensor in deutscher Qualität". Meine
Vermutung ist, das Bresser das einfach nur in China kauft und einen
eigenen Aufdruck aufs Gehäuse anbringt. :-(


### Stattdessen {#stattdessen}

Ich habe mir dann einen Template-Helper erzeugt, um die Luftfeuchte
nicht mehr vom Sensor zu bekommen, sondern von der Integration
"Meteorolisk institutt". Es gibt bei mir in der Gegend (in Bad
Nauheim) auch eine Wetterstation, deren Daten ich einsehen kann. Und
deren Werte stimmen grob mit dem überein, was "Meterorolisk institutt"
liefert. Aber was der Bresser-Sensor jetzt liefert ... passt leider
überhaupt nicht.

So legt man diesen Helfer an:

-   Settings
-   Devices &amp; Services
-   Helpers
-   Create helper
-   Template
-   Template a sensor
-   Name eintragen
-   "`{{ state_attr('weather.forecast_home','humidity') }}`" als State template
    template"
-   "%" als "Unit of Measurement"
-   "Humidity" könnte man als" Device class" eintragen, ich habe es allerdings leer
-   "Measurement" könnte man bei "State class" eintragen, ich habe es
    allerdings leer
-   "Device (to link to this entity)" lässt man leer

Das ganze sieht dann so aus:

{{< figure src="./bresser-luftfeuchte_template.png" >}}

Der Wert 96% oben ist exakt der Wert, die "`weather.forecase_home`" anzeigt:

{{< figure src="./bresser-weather-forecast-home.png" >}}

Übrigens könnte man für die Temperatur statt einem Außensensor die
Werte von "`weather.forecast` abgreifen !


## Batteriekapazitätsmesser - unbrauchbar! {#batteriekapazitätsmesser-unbrauchbar}

Diese ist **total unbrauchbar**. Sie kennt nur 100%.

Auch mit ziemlich leeren Batterien aus der Grabbelkiste habe ich kein
"battery_ok: 0" hinbekommen.

{{< figure src="./bresser-batterie.png" >}}

Ich ziehe Angaben von 0 und 100% **mit Zwischenwerten** da deutlich vor.
Sogar wenn die Prozentangabe bei NiMH-Akkus nicht stimmen sollte.


## Nutzung {#nutzung}

Ich nutze

-   die Daten des externen Sensors wie in
    [ Home-Assistant: Aldi Wetterstation ]({{< relref "aldi-wetterstation-ws0306w" >}})
    beschrieben
-   zusammen mit diesem Außensensor
-   und dem HACS-Plugin "Thermal Comfort"

zur Entscheidung "Lüften oder nicht?". Das HACS-Plugin erlaubt es
recht einfach, aus Temperatur + relativer Luftfeuchtigkeit die
absolute Luftfeuchtigkeit bzw. den Taupunkt zu berechnen. Und wenn man
diese beiden für innen und außen berechneten Werte vergleicht, kann
man sehr gut feststellen, ob man sich mit Lüften Feuchtigkeit ins Haus
holen würde.


## Kaufempfehlung? {#kaufempfehlung}

Nö
