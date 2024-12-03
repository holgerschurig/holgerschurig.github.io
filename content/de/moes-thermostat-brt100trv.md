+++
title = """
  Home-Assistant: Heizkörper-Thermostat "Moes BRT-100-TRV"
  """
author = ["Holger Schurig"]
date = 2024-12-02
tags = ["Heizkörper", "TRV", "Zigbee", "Moes", "BRT-100-TRV"]
categories = ["home-assistant"]
draft = false
+++

Hier geht es um den Zigbee-Heizkörper-Thermostat ("TRV") Moes
BRT-100-TRV. Also Zigbee-Modell wird "TS0601" angezeigt.

Vor allem aber geht es darum, warum man es nicht kaufen sollte :-/

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Einkauf - seltsamer Händler!](#einkauf-seltsamer-händler)
- [Einbindung in Home-Assistant - problemlos!](#einbindung-in-home-assistant-problemlos)
- [Anzeige](#anzeige)
- [Batterien - flexibel!](#batterien-flexibel)
- [Heizkörper-Anschluss](#heizkörper-anschluss)
- [Justierung - unklar](#justierung-unklar)
- [Temperaturmesser --- unbrauchbar!](#temperaturmesser-unbrauchbar)
- [Sensor für Lüftung / Fensteröffnung: funktionslos!](#sensor-für-lüftung-fensteröffnung-funktionslos)
- [Lautstärke - super!](#lautstärke-super)
- [Stellverhalten - nutzlos wg. Daten!](#stellverhalten-nutzlos-wg-dot-daten)
- [Firmware-Update](#firmware-update)
- [Kaufempfehlung?](#kaufempfehlung)

</div>
<!--endtoc-->

"TRV" steht übrigens für "Thermostatic Radiator Valve".


## Einkauf - seltsamer Händler! {#einkauf-seltsamer-händler}

Ich habe den Thermostat bei Aliexpress im Shop "MoesHouse Official
Store" gekauft.  Ein TRV hat hat mich ungefähr 28.99 EUR gekostet.

In der folgenden Kommunikation von GLS (dem Paketdienstleister) und
auch auf dem Versandlabel des Paketes stand dann nur "Online Seller".
**Ohne jede Adresse**.


## Einbindung in Home-Assistant - problemlos! {#einbindung-in-home-assistant-problemlos}

Das Gerät wird per Zigbee angebunden.

Ich verwende nicht ZHA, sondern Zigbee2MQTT und das hat den Thermostat
**problemlos erkannt**.

Die Assoziation startet übrigens automatisch sobald Batteriestrom da
ist. Also sollte man u.U. Zigbee2MQTT via Handy auf "Anlernen"
schalten, bevor man die Batterie einsetzt. (Generell sollte man
Zigbee-Devices ja nur an ihrem echten Einsatzort in das Netzwerk
einbinden, so werden sie gleich von Anfang an an die passende
Zigbee-Bridge angeflanscht.)

Siehe auch: <https://www.zigbee2mqtt.io/devices/BRT-100-TRV.html>


## Anzeige {#anzeige}

{{< figure src="/ox-hugo/brt100trv-montiert.jpeg" >}}

Man sieht, das die **Anzeige an der Stirnseite** ist. Das wäre für die
meisten Haushalte wohl eher schlecht. Da wäre eine um 180° drehbare
Anzeige an der Rundung wohl besser.

Für mich persönlich ist das aber nicht schlimm. Denn die Anzeige wird
m.E. durch Zigbee "mehr als ersetz", man hat mit Zigbee +
Home-Assistent viel mehr, als man durch die Anzeige hätte (wenn das
Gerät denn richtig messen würde, siehe unten ...).

-   man hat **bessere Einstellmöglichkeiten**, ohne sich durch
    Setup-Menüs quälen zu müssen
-   da die Entitäten nach Home-Assistant exportiert werden, hat
    man dort volle Gestaltungsmöglichkeiten in Dashboards. Oder
    Skipten. Oder Automatisierungen.
-   dort hat man auch Statistikfunktionen, und sei es nur der eingebaute
    Zeitreihen-Graph

Auszug aus Zigbee2MQTT:

{{< figure src="/ox-hugo/brt100trv-zigbee2mqtt.png" >}}

Es kommt noch etwa eine halbe Bildschirmseite weiterer
Einstellmöglichkeiten, also das Gerät exportiert wirklich recht
umfangreich!

Auch im Home-Assistant sind es viele, dort tauchen 17 Entitäten auf.
Ich verwende davon allerdings bisher nur ein Bruchteil --- und
verglichen mit den heftigen Nachteilen dieses TRV wird sich da wohl
auch nicht ändern.


## Batterien - flexibel! {#batterien-flexibel}

Es werden 3 Batterien vom Typ "AA" benötigt. Was ich für einen Vorteil
erachte gegenüber Sonderformen. Denn diese Batterien bekommt man nicht
nur als Wegwerfartikel, sondern auch aufladbar (z.B. als NiMH).

Leider hatte ich gerade keine NiMH da, also kamen drei
Wegwerfbatterien rein.

LiIon-Akkus, über USB wären vielleicht auch ganz gut ... ich will von
denen aber nicht zuviele im Haus haben, weil diese ja ein gewissen
Brandrisiko in sich bergen.

Die Batteriekapazität wird in Protent übertragen, mit einer
Schrittweite von einem halben Prozent, was ich **positiv** sehe:

{{< figure src="./batterie.png" >}}

(andere Geräte etwa wechseln zwischen 0% und 100% in einem Schritt)


## Heizkörper-Anschluss {#heizkörper-anschluss}

Ich habe von meinem alten Heizkörper den Thermostat abgeschraubt und
mir das Ventil angeschaut.

{{< figure src="/ox-hugo/brt100trv-ventil.jpeg" >}}

Und im Handbuch vom BRT-100-TRV sind auch einige Ventile abgebildet.
Jedoch ... sie sehen nicht so aus, wie mein Ventil:

{{< figure src="/ox-hugo/brt100trv-ventile.jpeg" >}}

Für diese 6 Typen gibt es auch Plastikadapter. Ich ich habe total
geschwommen, was denn nun der richtige wäre.

{{< figure src="/ox-hugo/brt100trv-ventile2.jpeg" >}}

Am ehesten passte dann die "Herz" - Variante ... aber welche der
beiden unterschiedlich langen Plastiknippel? Dieser Teil im Handbuch
ist **schlecht beschrieben**, finde ich.


## Justierung - unklar {#justierung-unklar}

Der Thermostat muss also sich auf die Länge des Ventil-Nippels
einstellen. Aber wie? Justiert sich der Thermostat von selbst ein? Wie
startet man diese Justage?  Wie überprüft man sie?  Beim Einschalten
redet das Handbuch von "F1" auf dem Display, und dann "F2" ebendort.

Ist der "F1"-Modus dies der Justage-Modes? Oder "F2"-Modus?

Das Englisch der Anleitung ganz okay (also kein Chenglisch) ... aber
**solche Details werden nicht erklärt**.


## Temperaturmesser --- unbrauchbar! {#temperaturmesser-unbrauchbar}

Die Temperatur wird nur in vollen Graden gemessen, nicht in
Zehntelgrad. Das finde ich schonmal **schlecht**.

Aber, schlimmer noch: vermutlich wird die Temperatur **falsch** gemessen:

{{< figure src="/ox-hugo/brt100trv-temperatur.png" >}}

-   der Messwort soll angeblich 19°C sein. Das zeigt keines meiner
    anderen Thermometer im Esszimmer oder Wohnzimmer (derselbe Raum).
    Die zeigen ca 22°C an. Das Haus hat ein Wärmedämmverbundsystem, also
    wird es auch an der Außenwand nicht gleich 3 Kelvin kälter sein ---
    zumal in unmittelbarer Nähe zum Heizkörper.
-   sicher, es gibt eine --- vom Hersteller vollkommen undokumentierte!
    --- Temperatur-Kalibration in Zigbee2MQTT. Aber an sich erwarte ich,
    das ein Gerät ab Werk korrekte Temperaturwerte anzeigt. "Tante Erna"
    wird schwerlich über Zigbee das Gerät kalibrieren können. Das sie es
    überhaupt muss ist an sich schon **schlecht**.
-   laut Zigbee2MQTT wurde das Gerät zuletzt vor 3 Stunden gesehen ...
-   ... aber die 19°C bestehen angeblich seit 17 Stunden??!  Der
    Thermostat meint also, seit 17 Stunde wäre nie gelüftet worden, die
    Tag/Nachtregelung der Heizung wäre nicht aktiv?  (andere Thermometer
    zeigen durchaus Temperaturänderungen von mehr als 1 Kelvin an)

**Das ganze ist so unerquicklich das ein mechanischer Thermostat mit
Bimetall eigentlich besser ist**.


## Sensor für Lüftung / Fensteröffnung: funktionslos! {#sensor-für-lüftung-fensteröffnung-funktionslos}

Ein geöffnetes Fenster wird auch **nicht erkannt**, obwohl dies via
Zigbee2MQTT aktiviert wurde.

Warum kann man das überhaupt abschalten ... wer's nicht braucht, würde
den entsprechenden Sensor halt einfach nicht in eine Anzeige packen
und nicht in eine Automatisierung packen!

Hier die Doku: draußen ist es gerade 4°C kalt. Und wenn ich auf allen
Stockwerken die Fenster öffne, wird im Haus wg. Bernoulli-Effekt sehr
schnell die Luft ausgetauscht. Die Temperatur ändert sich sehr
schnell. Aber der Sensor dafür des BRT-100-TRV zeigt das nicht an:

{{< figure src="/ox-hugo/brt100trv-fenster.png" >}}


## Lautstärke - super! {#lautstärke-super}

Unhörbar!


## Stellverhalten - nutzlos wg. Daten! {#stellverhalten-nutzlos-wg-dot-daten}

{{< figure src="/ox-hugo/brt100trv-stellverhalten.png" >}}

Jeweils nach 5 Minuten scheint der Thermostat eine neue Entscheidung
zu fällen.

Er stellt das Ventil jedoch **nicht stetig** ein, sondern hat einige
wenige diskrete Stellungen für die Ventilöffnung.

Es ist aber vollkommen unklar, warum manchmal gestellt wird. Wie
sollte sich um 3 Uhr nachts die Temperatur so stark ändern, das man
nachregeln muss (da habe ich schon einige Stunden geschlafen ...):

{{< figure src="/ox-hugo/brt100trv-3uhr-position.png" >}}

Okay, der Temperatursensor hat gemeint, das sich die Temperatur
schlagartig um 2 K abgesenkt hat:

{{< figure src="/ox-hugo/brt100trv-3uhr-temperatur.png" >}}

Aber das entspricht nicht der Wahrheit. Andere Temperatursensoren
zeigten nichts derartiges an.


## Firmware-Update {#firmware-update}

Der Reiter "OTA" von Zigbee2MQTT bietet mir für dieses Gerät kein
Firmware-Update an.


## Kaufempfehlung? {#kaufempfehlung}

Ein kräftiges **Nein**, ich würde mir diese TRVs nicht nochmal kaufen
und rate das auch keinem anderen.
