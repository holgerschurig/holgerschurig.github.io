+++
title = "Home-Assistant: IKEA Schalter Styrbar E2001"
author = ["Holger Schurig"]
date = 2024-12-04
tags = ["Steckdose", "Zigbee", "Ikea", "Styrbar", "E2001"]
categories = ["home-assistant"]
draft = false
+++

Hier geht es um den IKEA Schalter "Styrbar" E2001.

Und um 4 sehr verschiedene Arten, auf Tastendrücke zu reagieren
(Action, Pyscript, Switch Manager, Blueprint).

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Abmessungen](#abmessungen)
- [Einkauf](#einkauf)
- [Batterie](#batterie)
- [Einbindung in Home-Assistant - problemlos!](#einbindung-in-home-assistant-problemlos)
- [Nutzung in Home-Assistant - anspruchsvoll!](#nutzung-in-home-assistant-anspruchsvoll)
- [Entities in Home-Assistant](#entities-in-home-assistant)
- [Tasten-Events herausfinden](#tasten-events-herausfinden)
- [Tasten-Events herausfinden (mit mehr Details)](#tasten-events-herausfinden--mit-mehr-details)
    - [Oben](#oben)
    - [Links](#links)
    - [Rechts](#rechts)
    - [Unten](#unten)
- [Tastenevents nutzen](#tastenevents-nutzen)
    - [In Aktion den Trigger setzen](#in-aktion-den-trigger-setzen)
    - ["Pyscript" von HACS - für Programmierer](#pyscript-von-hacs-für-programmierer)
    - ["Switch Manager" von HACS - einfach!](#switch-manager-von-hacs-einfach)
    - [Blueprints](#blueprints)
- [Kaufempfehlung?](#kaufempfehlung)

</div>
<!--endtoc-->


## Abmessungen {#abmessungen}

Der Schalter misst ca. 7 cm im Quadrad und ist ca. 1.5 cm hoch

{{< figure src="./e2001.jpeg" >}}


## Einkauf {#einkauf}

Ich habe den Schalter bei IKEA in Frankfurt selbst
gekauft. Den Preis habe ich vergessen, im Dez. 2024 kostet er knapp 10
EUR.


## Batterie {#batterie}

Es werden 2 AAA Batterien gebraucht.

Ich habe derzeit noch Alkaline (Wegwerf) Batterien drin und kann also
nicht sagen, ob aufladbare NiMH auch funktionieren würden.

Die Batterie wird in 1er Schritten zwischen 0% und 100% übermittelt.
Zumindest glaube ich das, aber meine Home-Assistant interne History
zeigt für die gespeicherten 3 Tage immer 90% an.

Ich nutze den Taster jetzt schon seit einem dreiviertel Jahr.


## Einbindung in Home-Assistant - problemlos! {#einbindung-in-home-assistant-problemlos}

Das Gerät wird von Zigbee2MQTT ohne Probleme erkannt und eingebunden.

Siehe auch: <https://www.zigbee2mqtt.io/devices/E2001_E2002.html>

Man kann dann in Zigbee2MQTT diese Geräte-Details sehen:

{{< figure src="./e2001-zigbee2mqtt.png" >}}


## Nutzung in Home-Assistant - anspruchsvoll! {#nutzung-in-home-assistant-anspruchsvoll}


## Entities in Home-Assistant {#entities-in-home-assistant}

In Home-Assistant findet man dann ähnlich Entities:

{{< figure src="./e2001-entities.png" >}}

Die wichtige für die Automatisierung ist hier die mit "`_action`" am
Ende.


## Tasten-Events herausfinden {#tasten-events-herausfinden}

Doch welche Aktionen sind bei der "`_action`" Entity möglich?  Das
können wir herausfinden:

-   Settings
-   Devices &amp; services
-   Devices
-   "Styrbar" suchen und klicken

Auf der rechten Seite sieht man dann im Logbook die Events:

{{< figure src="./e2001-events.png" >}}


## Tasten-Events herausfinden (mit mehr Details) {#tasten-events-herausfinden--mit-mehr-details}

Wenn man mehr Details sehen will, geht man dorthin:

-   Developer Tools
-   Events
-   Listen to Events
-   "state_changed" eintragen
-   Start Listening

und drücken die obere Taste (die mit der Vertiefung) dann sehen wir:

```text
vent_type: state_changed
data:
  entity_id: sensor.ikea_styrbar_4fach_taster_action
  old_state:
    entity_id: sensor.ikea_styrbar_4fach_taster_action
    state: ""
    attributes:
      icon: mdi:gesture-double-tap
      friendly_name: IKEA STYRBAR 4fach Taster Action
    last_changed: "2024-12-04T09:28:26.697913+00:00"
    last_reported: "2024-12-04T09:28:26.697913+00:00"
    last_updated: "2024-12-04T09:28:26.697913+00:00"
    context:
      id: 01JE8FZPA9GTNNPJV4D8FFA02Z
      parent_id: null
      user_id: null
  new_state:
    entity_id: sensor.ikea_styrbar_4fach_taster_action
    state: "on"
    attributes:
      icon: mdi:gesture-double-tap
      friendly_name: IKEA STYRBAR 4fach Taster Action
    last_changed: "2024-12-04T09:30:01.098844+00:00"
    last_reported: "2024-12-04T09:30:01.098844+00:00"
    last_updated: "2024-12-04T09:30:01.098844+00:00"
    context:
      id: xxxxxxxxxxxxxxxxxxxxxxxxxx
      parent_id: null
      user_id: null
origin: LOCAL
time_fired: "2024-12-04T09:30:01.098844+00:00"
context:
  id: xxxxxxxxxxxxxxxxxxxxxxxxxx
  parent_id: null
  user_id: null
```

Beim Loslassen dasselbe, nur steht da halt unter "new_state.state"
kein `"on"` mehr, sondern der leere String `""`.

Und das reicht nun aus, um eine Automatisierung zu erstellen.

Wichtig: die 4 Tasten erzeugen unterschiedliche Datensätze. Hier mal
die Datensätze beim kurzen Tippen. Beim langen Tippen kommen andere
Datensätze. Und weil die wenigesten Zeilen von oben gebraucht werden,
hier nur das Relevante:


### Oben {#oben}

```text
...
date:
   ...
   new_state:
     entity_id: sensor.ikea_styrbar_4fach_taster_action
     state: "on"
...
```


### Links {#links}

```text
...
date:
   ...
   new_state:
     entity_id: sensor.ikea_styrbar_4fach_taster_action
     state: arrow_left_click
...
```


### Rechts {#rechts}

```text
...
date:
   ...
   new_state:
     entity_id: sensor.ikea_styrbar_4fach_taster_action
     state: arrow_roght_click
...
```


### Unten {#unten}

```text
...
date:
   ...
   new_state:
     entity_id: sensor.ikea_styrbar_4fach_taster_action
     state: "off"
...
```

Eher nicht wichtig, aber doch bemerkenswert: manchmal kommt der State in
Gänsefüßchen. Und manchmal nicht.


## Tastenevents nutzen {#tastenevents-nutzen}

Nun wissen wir, was die Tasten so senden. Und nun wollen wir natürlich
darauf reagieren.


### In Aktion den Trigger setzen {#in-aktion-den-trigger-setzen}

-   Settings
-   Automations &amp; Scenes
-   Automations
-   Create Automation
-   "When" öffnen
-   den IKEA-Taster in der ersten Entity auswählen
-   zweites Entity-Feld leer lassen
-   "Attribute" leer lassen
-   "From" leer lassen
-   "To" mit `on` füllen. Auch wenn im Log oben `"on"` stand, braucht
    man hier im GUI keine Gänsefüßchen
-   bei "Then do" passende Dinge ausfüllen

Oder grafisch:

{{< figure src="./e2001-trigger.png" >}}

Oder in YAML:

```text
alias: TEST STYRBAR
description: ""
triggers:
  - trigger: state
    entity_id:
      - sensor.ikea_styrbar_4fach_taster_action
    to: "on"
conditions: []
actions:
  - action: switch.toggle
    metadata: {}
    data: {}
    target:
      entity_id: switch.neo_steckdose_1
mode: single
```


### "Pyscript" von HACS - für Programmierer {#pyscript-von-hacs-für-programmierer}

Da ich ja Programmierer bin, finde ich es oft umständlich, mir über
ein GUI etwas zusammenzuklicken, was doch in einer Programmiersprache
recht einfach wäre. Also habe ich mir in HACS mal [pyscript](https://github.com/custom-components/pyscript)
installiert und nach deren Anleitung installiert.

Und dann kann man so auf die Taste reagieren. Hier ein Auszug aus
meiner "`pyscript/regalbeleuchtung.py", die sich wiederum im
"=/config`" meines Home-Assistant befindet:

```text
@state_trigger("sensor.ikea_styrbar_4fach_taster_action == 'on'")
def regal_an_py(**kwargs):
  switch.toggle(entity_id="switch.neo_steckdose_1")
```

Das ganze sind drei Zeilen, viel einfacher als das YAML oben.

In Wirklichkeit ist die Datei noch ein wenig größer, da ich oft Links
auf Doku oder Hinweise zum Debuggen mit aufnehme:

```text
# https://hacs-pyscript.readthedocs.io/en/stable/tutorial.html
#
# See log.XXX() output with: tail -f /homeassistant/home-assistant.log


# https://hacs-pyscript.readthedocs.io/en/stable/reference.html#state-trigger
@state_trigger("sensor.ikea_styrbar_4fach_taster_action == 'on'")
def regal_an_py(**kwargs):
  # log.warning(f"mymqtt {kwargs}")
  switch.toggle(entity_id="switch.neo_steckdose_1")
```

-   sobald ich eine neues Script von meinem Editor in die Home-Assistant
    VM auf Proxmoxx kopiere ist sie bereits aktiv. Man muss nichts in
    den Developer-Tools neuladen
-   oben steht ein "tail -f"-Befehl. Dort würde man die typischen
    Python-Fehler sehen, wenn man Syntax-Fehler drin hat
-   den auskommentiere "`log.warning(...)`" Befehl kann man aktivieren,
    um zusätzliche Debug-Info zu bekommen.

Also, für **mich** als Programmierer ist das einfach. Aber es geht noch einfacher:


### "Switch Manager" von HACS - einfach! {#switch-manager-von-hacs-einfach}

Seit einiger Zeit gibt es eine einfachere Möglichkeit. Im
Home-Assistant Community Store (HACS) findet man den
[Switch Manager](https://github.com/Sian-Lee-SA/Home-Assistant-Switch-Manager). Sobald er installiert ist, findet man "Switch Manager"
im Sidebar und kann dort mit "Add Switch" einen von vielen Switches
hinzufügen.

Das habe ich mit diesem IKEA Switch getan und bekomme dann dieses GUI:

{{< figure src="./e2001-switch-manager.png" >}}

Ich klicke dann zunächst einen der Buttons (hier ist gerade der obere
aktiv). Und dann kann ich unten drei verschiedene Aktion für

-   Press (kurzes Tippen)
-   Hold (langes Anhalten ... Aktion wird gestartet sobald langes Halten
    erkannt wird)
-   Release (langes Anhalt ... Aktion wird beim Loslassen gestartet)

definieren.

Einfacher geht's nicht!


### Blueprints {#blueprints}

Diese möchte ich nur erwähnen. Wenn man nach [home-assistant styrbar
bluebprint](https://letmegooglethat.com/?q=home-assistant+styrbar+blueprint) sucht, findet man einige Treffer. Sie haben aber nicht
exakt das getan, was ich wollte. Beispielsweise steuere ich über
diesen Taste sowohl meine Regalbeleuchtung als auch mein (fast)
werbefreies Internet-Radio. Das Blueprint, das ich gefunden hatte,
wollte damit nur Licht steuern.


## Kaufempfehlung? {#kaufempfehlung}

**Ja**, ich finde diesen Schalter für den Preis voll in Ordnung.

Durch die Metallkappe hat er keine Billigst-Anmutung.

An die Wand kleben (als Ersatz für einen normalen Lichtschalter) würde
ich ihn aber nicht wollen. Aber so wandert er von meinen
Programmier-Schreibtisch auf den
Für-die-Firma-programmieren-Schreibtisch oder zum Couchtisch. Je
nachdem, wo ich ihn gerade brauche.

Als Fernsteuerung für mein (fast) werbefreies Internet-Radio ist er
viel besser als eine Infrarot-Fernbedienung es wäre.
