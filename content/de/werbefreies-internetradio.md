+++
title = "Home-Assistant: (fast) werbefreies Internetradio"
author = ["Holger Schurig"]
date = 2024-12-09
tags = ["Styrbar", "E2001"]
categories = ["home-assistant"]
draft = false
+++

Wir erstellen uns ein Internet-Radio mit einer Pausen-Funktion zu
festen Uhrzeiten. Damit können wir bei einigen Sendern die nervige
Werbung ausblenden.

Außerdem: warum der Home-Assistant-Radio-Browser nichts taugt. Und
eine USB-Soundbar besser ist als ein Sonos- oder Symfonisk-Lautsprecher.

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [Grund](#grund)
- [Was man braucht](#was-man-braucht)
    - [Radio Browser - lieblos!](#radio-browser-lieblos)
    - [Radio-Browser, diesmal per Web](#radio-browser-diesmal-per-web)
- [Internetradio](#internetradio)
    - [Service-Aufruf](#service-aufruf)
    - [Helferlein](#helferlein)
    - [Script: nächster Sender](#script-nächster-sender)
    - [Script: vorheriger Sender](#script-vorheriger-sender)
    - [Scripte: Sender starten](#scripte-sender-starten)
    - [Script: Weitermachen](#script-weitermachen)
    - [Script: Radio Pausieren](#script-radio-pausieren)
    - [Script: Radio aus](#script-radio-aus)
    - [Script: Radio Start/Stop](#script-radio-start-stop)
- [Bedienung](#bedienung)
    - [GUI](#gui)
    - [Taster](#taster)
- [Werbepause](#werbepause)
- [Verbesserungspotential](#verbesserungspotential)

</div>
<!--endtoc-->


## Grund {#grund}

Wer mag ihn nicht, den nervigen Herrn Seitenbacher der uns seit Jahren
mit unendlichen Wiederholungen traktiert?

Oder die unvorteilhaften Stimmen von LILD und Kaufland, deren einzige
Qualifikation wahrscheinlich die Aussprache ist ... und das sie
maximal nervend sind, um Aufmerksamkeitsheischend zu unseren
Gehirnzellen vorzudringen?

Wer mag sie nicht .... **ICH** !!!


## Was man braucht {#was-man-braucht}

Man muss ein Sound-Device haben, welches als
"`media_player.irgendwas`" erreichbar ist.

Zwei Beispiele von vielen:

**Symfonisk- oder Sonos-Lautsprecher**

Diese werden beide durch die [Sonos-Integration](https://www.home-assistant.io/integrations/sonos) unterstützt. Allerdings
kann man diese nicht empfehlen:

-   die Sonos-App für Android funktioniert seit Monaten nicht und hat
    deshalb unterirdische Bewertungen
-   der Symfonisk/Sonos-Lautsprecher reagiert sehr langsam auf
    Abspielkommandos. Stoppen geht hingegen recht schnell.
-   aber er spielt auch langsam ab. Zwischen der USB/VLC basierter
    Soundbar und dem Symfonisk-Lautsprecher gibt es eine **mächtige**
    Verzögerung. Über USB kommt der Sound fast eine Sekunde schneller
    als via Symfonisk/Sonos.

**USB-Lautsprecher**

Ich hatte aber noch eine "Creative Stage V2 Soundbar". Diese hat u.A.
USB. Und ich habe sie darüber an meinen Intel NUC angeschlossen, auf
dem Home-Assistant innerhalb von Proxmox läuft. Das ganze sieht grob
so aus:

{{< figure src="werbefreies-internetradio.png" >}}

Was auch immer man macht, man braucht für alles folgende ein
funktionierendes "`media_player.*`" Device!


### Radio Browser - lieblos! {#radio-browser-lieblos}

Es gibt den integrierten
[Radio Browser](https://www.home-assistant.io/integrations/radio_browser/) nutzen. Aber dessen Datenbasis ist... unterirdisch. Wenn
man links auf "Media" und dann auf "Radio Browser" klickt, sieht man
die Landesflaggen.

Also runter zu "Germany". Huch, da gibt's ja zwei?  Ich dachte, das
wäre Geschichte. Aber wo sind bei der zweiten Flagge dann Hammer und Sichel?

{{< figure src="./werbefreies-internetradio-radiobrowser.png" >}}

Klickt man auf eine, dann auf den Zurückbutton des Radio-Browser
(nicht von Firefox/Chromium etc ...) dann landet man ... wieder an
Anfang der Länderliste. **Die Position wird sich nicht gemerkt**, ich
muss wieder runterscrollen.

Wenn ich dann auf eine der deutschen Flagge klicke ... welche ist egal
.. dann kommen Radiosender. Doch sie erscheinen irgendwie unsortiert.

Bis man merkt, das auch da Aufmerksamkeitsheischende Leutchen
**getrickst** haben. Ein "  90s" (zwei Leerzeichen) wird halt, wenn man stur nach
ASCII-Alphabet sortiert, vor "HR3" angezeigt. Wäre ich der
Plugin-Autor, würde ich diese Tricks-Namen einfach herausfiltern.

Apropos "HR3"... man suche nun mal diesen Sender. Fast unmöglich, weil
es **keine Suchfunktion** gibt. Also ist Suchen per Scrollen und Lesen angesagt.

Page-Up und Page-Down **gehen natürlich auch nicht**.

Nehmen wir mal an, wir sind glücklich bei HR3 gelandet. Klickt man nun
auf den Zurück-Button des Radio-Browsers, sucht erneut die deutsche
Flagge, und klickt dann wieder darauf ... ist man **wieder am Anfang**.
Und darf wieder suchen.

Und wenn ich nun einen Sender per Automation hören will ... hier
findet man keine Information, wie das denn gehen könnte. Wie ich also
z.B. den HR3-Button automatisiert drücken könnte.

Am besten vergessen wir den eingebauten "Radio Browser" ganz schnell.
Das ist insgesamt ein grausames UI.


### Radio-Browser, diesmal per Web {#radio-browser-diesmal-per-web}

Aber woher holt sich Home-Assistant überhaupt die Sender? Von
<https://www.radio-browser.info/> --- man findet da zwar auch die
getricksten Sendernamen. Aber wenigstens gibt es eine Suchfunktion.

Also oben rechts "hr3" eingeben und schon hat man die Streams:

{{< figure src="./werbefreies-internetradio-radiobrowserinfo.png" >}}

Wenn man nun auf einen der Einträge klickt, sieht in der Adresszeile
von Firefox/Chromium URLs dieser Art:

<https://www.radio-browser.info/history/c9f56165-ab64-4af8-ba90-dfb0aa735218>

Und dieses "**c9f56165-ab64-4af8-ba90-dfb0aa735218**" (eine sog. UUID)
ist nun das, was wir gleich in Home-Assistant brauchen werden.

Wir nutzen also <https://www.radio-browser.info>, um die UUIDs der Sender zu erfahren.


## Internetradio {#internetradio}


### Service-Aufruf {#service-aufruf}

Was macht man nun mit der UUID?  Zunächst einen Test! In den
Developer-Tools gibt man das ein:

{{< figure src="./werbefreies-internetradio-developertools.png" >}}

bzw. dieses YAML:

```text
action: media_player.play_media
target:
  entity_id: media_player.soundbar_wz
data:
  media_content_id: media-source://radio_browser/c9f56165-ab64-4af8-ba90-dfb0aa735218
  media_content_type: music
```

Wir sehen hier "`media-source://radio_browser/`" gefolgt von unser
eben herausgefunden UUID.

Wenn wir das nun als Script (statt in den Developer Tools) anlegen,
können wir es in Automationen, GUI-Elementen nutzen.

{{< figure src="./werbefreies-internetradio-buttons.png" >}}

... oder mit [ Hardware-Schaltern ]({{< relref "ikea-schalter-e2001" >}})
steuern.


### Helferlein {#helferlein}

Wir erstellen uns zwei String-Helfer. Das geht so:

-   Settings
-   Devices &amp; services
-   Helpers
-   Create helper
-   Text
-   Name: "Radio Sender"
-   Icon: nach belieben

Und dann noch einen Helfer dieser Art für "Radio UUID":

{{< figure src="./werbefreies-internetradio-helfer.png" >}}


### Script: nächster Sender {#script-nächster-sender}

Diese Helfer werden in den folgenden Skripten genutzt. Beispielsweise
wie hier für eine Funktion, um zum nächsten Sender zu springen:

```text
script:
  radio_next:
    alias: "Radio Next"
    sequence:
      - choose:
          - conditions:
              - condition: template
                value_template: "{{ states('input_text.radio_sender') == '' }}"
            sequence:
              - action: script.radio_hr1
          - conditions:
              - condition: template
                value_template: "{{ states('input_text.radio_sender') == 'HR1' }}"
            sequence:
              - action: script.radio_hr3
          - conditions:
              - condition: template
                value_template: "{{ states('input_text.radio_sender') == 'HR3' }}"
            sequence:
              - action: script.radio_hrinfo
          - conditions:
              - condition: template
                value_template: "{{ states('input_text.radio_sender') == 'hr INFO' }}"
            sequence:
              - action: script.radio_dlf
          - conditions:
              - condition: template
                value_template: "{{ states('input_text.radio_sender') == 'DLF' }}"
            sequence:
              - action: script.radio_dlfnova
          - conditions:
              - condition: template
                value_template: "{{ states('input_text.radio_sender') == 'DLF Nova' }}"
            sequence:
              - action: script.radio_hr1
```

(Das YAML startet mit "`script:`" weil ich Home-Assistant's [Packages](https://www.home-assistant.io/docs/configuration/packages/)
verwende. Ich habe alle Media-Script in `/config/packages/media.yaml`
gesammelt. Wer das YAML direkt in den Editor reinhaut, muss es
entsprechend anpassen.)

Im Prinzip ist das, analog zu C, ein switch/case Statement. Und die
Bedingungen wird über ein Template festgelegt.


### Script: vorheriger Sender {#script-vorheriger-sender}

Das Script für "vorheriger Sender" ist analog wie "nächster Sender" aufgebaut.


### Scripte: Sender starten {#scripte-sender-starten}

Dieses Script setzt die beiden Helfer auf Text und UUID. Es ruft nicht
direkt media_player.play_media auf. Denn ich brauche die UUID für eine
Pause/Continue-Funktion. Und wenn ich sowieso eine Continue-Funktion
erstellen werden, kann ich die auch gleich hier aufrufen:

```text
script:
  radio_hr1:
    alias: "Radio HR1"
    sequence:
      - action: input_text.set_value
        target:
          entity_id: input_text.radio_sender
        data:
          value: "HR1"
      - action: input_text.set_value
        target:
          entity_id: input_text.radio_uuid
        data:
          value: "600c73d1-2ea5-45ee-b3c1-c108674343e6"
      - action: script.radio_continue
```

Dieses Script erstelle ich dann abgewandelt für alle Sender die ich
per Button starten will: HR1, HR3, hr-info, DLF, DLF Nova.


### Script: Weitermachen {#script-weitermachen}

Hier ist das "`script.radio_continue`", das oben aufgerufe wurde:

```text
script:
  radio_continue:
    alias: "Radio Continue"
    sequence:
      - action: media_player.play_media
        target:
          entity_id: media_player.soundbar_wz
        data:
          media_content_type: music
          media_content_id: "media-source://radio_browser/{{ states('input_text.radio_uuid') }}"
```


### Script: Radio Pausieren {#script-radio-pausieren}

Und da "`script.radio_continue`" ja mit einer Pause-Funktion
zusammenspielen soll, brauchen wir die auch noch:

```text
radio_pause:
  alias: "Radio Pause"
  sequence:
    - action: media_player.media_stop
      target:
        entity_id: media_player.soundbar_wz
```


### Script: Radio aus {#script-radio-aus}

Wenn wir hingegen richtig asusschalten wollen, dann Stoppen wir den
Media-Player und setzen auch die Helfer zurück.

Andere Script können dann am leeren UUID-Feld erkennen, das das Radio
in wirklich aus ist (es soll also z.B. zur vollen Stunde wieder
angemacht werden, etwa nach einer Werbepause).

```text
script:
  radio_off:
    alias: "Radio Off"
    sequence:
      - action: media_player.media_stop
        target:
          entity_id: media_player.soundbar_wz
      - action: input_text.set_value
        target:
          entity_id: input_text.radio_sender
        data:
          value: ""
      - action: input_text.set_value
        target:
          entity_id: input_text.radio_uuid
        data:
          value: ""
```


### Script: Radio Start/Stop {#script-radio-start-stop}

Dieses Script habe ich auf eine Hardware-Taste (IKEA Styrbar) gelegt:

```text
script:
  radio_startstop:
    alias: "Radio Start/Stop"
    sequence:
      - if:
          - condition: state
            entity_id: input_text.radio_sender
            state: ""
        then:
          - action: script.radio_hr1
        else:
          - if:
              - condition: state
                entity_id: media_player.soundbar_wz
                state: "playing"
            then:
              - action: script.radio_pause
            else:
              - if:
                  - condition: state
                    entity_id: media_player.soundbar_wz
                    state: "idle"
                then:
                  - action: script.radio_continue
```

-   läuft kein Sender: wird HR1 gestartet
-   läuft ein Sender: dann rufe ich das Pausen-Script auf
-   ansonsten wird "Radio Continue" aufgerufen


## Bedienung {#bedienung}


### GUI {#gui}

Ich habe mir ein Dashboard angelegt, das mir einfachen Zugriff auf die
Sender ermöglicht:

{{< figure src="./werbefreies-internetradio-webgui.png" >}}


### Taster {#taster}

Aber meistens nehme ich den [ IKEA Styrbar ]({{< relref "ikea-schalter-e2001" >}}) --- mit
[Switch Manager](https://github.com/Sian-Lee-SA/Home-Assistant-Switch-Manager) folgermaßen beschaltet:

{{< figure src="./werbefreies-internetradio-schalter.png" >}}

-   Oben: Licht
-   Links: vorheriger Sender
-   Rechts: nächster Sender
-   Unten: Pause bzw. Weiter, bei langen Drücken: Stop

Dieser Schalter wandert von meinem PC-Schreibtisch zum
Wohnzimmer-Couchtisch zum Home-Office, wo er gerade gebraucht wird.


## Werbepause {#werbepause}

Bisher haben wir nur ein Internet-Radio. Aber wie machen wir das nun
mit der Werbung?  Im Prinzip nutzen wir aus, das Werbung in vielen
Sendern zur festen Uhrzeit kommt. Wir schalten dann einfach das Radio
auf "Pause":

```text
automation:
  - alias: "Radio wg. Werbung aus (HR1)"
    triggers:
      - trigger: time_pattern
        minutes: "27"
      - trigger: time_pattern
        minutes: "57"
    conditions:
      # - condition: state
      #   entity_id: binary_sensor.feiertag
      #   state: "off"
      - condition: time
        after: "6:00:00"
        before: "20:00:00"
      - condition: time
        weekday:
          - mon
          - tue
          - wed
          - thu
          - fri
          - sat
      - condition: state
        entity_id: input_text.radio_sender
        state: "HR1"
    actions:
      - action: script.radio_pause
    mode: restart
```

(Auch hier steht wieder ein "`automation:`" davor, weil dieses YAML
gemeinsam mit den Scripten von oben in einer
Home-Assistant-[Packages](https://www.home-assistant.io/docs/configuration/packages/)-Datei steht. Wer das in sein GUI rainhauen
will, passt es entsprechend an.)

Wir pausieren also zwischen 6 und 20 Uhr das Radio jeweils 3 Minuten
vor der vollen Stunde und halben Stunde.

Noch auskommentiert sieht man, wie man diesen "Werbeblocker" auch an
Feiertagen festmachen könnte.

Wenn wir pausieren, dann wollen wir aber auch irgendwann wieder
fortfahren:

```text
automation:
  - alias: "Radio nach Werbung an (HR1)"
    triggers:
      - trigger: time_pattern
        minutes: "0"
      - trigger: time_pattern
        minutes: "32"
    conditions:
      # - condition: state
      #   entity_id: binary_sensor.feiertag
      #   state: "off"
      - condition: state
        entity_id: input_text.radio_sender
        state: "HR1"
    actions:
        action: script.radio_continue
    mode: restart
```

Für HR3 ist das ähnlich, nur senden sie die Werbung zur viertel- und
dreiviertel Stunde.

hr-info sendet so wenig Werbung, das ich da nichts implementiert habe.
DLF und DLF Nova sind sowieso vollkommen Werbefrei.


## Verbesserungspotential {#verbesserungspotential}

Besser wäre es vermutlich, wenn man die Jingles vor der Werbung
erkennt. Da wir potentielle viele Strings erkennen sollten, wäre
vielleicht eine [Robin-Karp-Suche](https://de.wikipedia.org/wiki/Rabin-Karp-Algorithmus) praktisch. Zu jedem Suchmuster könnte
man eine Pausen-Zeit eintragen.

Dieser Suche nach Werbung oder Werbe-Jingles könnte Rundfunk über
Stream empfangen (wie oben). Oder man könnte sie in einen
Software-DAB+-Empfänger mit Hilfe eine günstigen [RTL-SDR](https://www.rtl-sdr.com/)-Stick
einbauen. Ein Beispiele wäre [DABlin](https://github.com/Opendigitalradio/dablin) oder [Welle.io](https://www.welle.io/).
