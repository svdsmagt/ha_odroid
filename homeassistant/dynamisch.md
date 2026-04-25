Oké, hier is een volledige, praktische samenvatting voor jouw NIBE S320 + HomeWizard P1 + Home Assistant setup. Dit kan je zo uitleggen of gebruiken om te implementeren.
________________________________________
1️⃣ Doel
•	Gebruik PV-overschot om NIBE warmtepomp extra te laten verbruiken.
•	Laat NIBE dynamische tarieven en optimalisatie zelf regelen.
•	Home Assistant stuurt alleen SG3-signaal (overschot ja/nee).
•	Failsafe voorkomt dat NIBE in SG3 “blijft hangen”.
________________________________________
2️⃣ Benodigdheden
•	NIBE S320 / S-series warmtepomp, Modbus TCP actief
•	HomeWizard P1 meter, aangesloten op slimme meter
•	Home Assistant op hetzelfde netwerk als NIBE
•	Één Modbus TCP switch in HA: switch.heating_sg_ready_40761_2
________________________________________
3️⃣ Werking NIBE Smart Grid Ready
Input	Waarde	Operating mode	Betekenis
A=0, B=0	uit	SG0 / SG2	Normaal bedrijf
A=1, B=1	aan	SG3	PV-overschot → extra verbruik toegestaan
De switch in HA zet automatisch A+B = 1 bij overschot. NIBE regelt zelf boiler/warmtepomp/prijsoptimalisatie.
________________________________________
4️⃣ Home Assistant configuratie
4a. Modbus TCP
modbus:
  - name: nibe
    type: tcp
    host: 192.168.1.60   # IP van NIBE
    port: 502
4b. Switch voor SG3
switch:
  - platform: modbus
    write_type: holding
    registers:
      - name: heating_sg_ready_40761_2
        hub: nibe
        slave: 1
        address: 20-21  # gecombineerde A+B
        command_on: 1
        command_off: 0
4c. PV-overschot sensor
binary_sensor:
  - platform: template
    sensors:
      pv_overschot:
        friendly_name: "PV overschot"
        value_template: "{{ states('sensor.homewizard_power')|int < -1000 }}"
(negatief = teruglevering, pas drempel aan)
________________________________________
5️⃣ Automatisering: overschot doorgeven
automation:
  - alias: "NIBE SG3 bij PV overschot"
    mode: single
    trigger:
      - platform: state
        entity_id: binary_sensor.pv_overschot
    action:
      - choose:
          - conditions:
              - condition: state
                entity_id: binary_sensor.pv_overschot
                state: "on"
            sequence:
              - service: switch.turn_on
                target:
                  entity_id: switch.heating_sg_ready_40761_2
        default:
          - service: switch.turn_off
            target:
              entity_id: switch.heating_sg_ready_40761_2
________________________________________
6️⃣ Failsafe
6a. Bij HA restart
automation:
  - alias: "NIBE failsafe bij HA start"
    trigger:
      - platform: homeassistant
        event: start
    action:
      - service: switch.turn_off
        target:
          entity_id: switch.heating_sg_ready_40761_2
6b. Optioneel: max SG3 tijd
automation:
  - alias: "Max SG3 tijd"
    trigger:
      - platform: state
        entity_id: binary_sensor.pv_overschot
        to: "on"
    action:
      - delay:
          hours: 2
      - service: switch.turn_off
        target:
          entity_id: switch.heating_sg_ready_40761_2
6c. Hysterese (stabiel signaal)
binary_sensor:
  - platform: template
    sensors:
      pv_overschot:
        value_template: "{{ states('sensor.homewizard_power')|int < -1500 }}"
        delay_on: "00:02:00"
        delay_off: "00:05:00"
________________________________________
7️⃣ Controlepunten
1.	Zet switch.heating_sg_ready_40761_2 aan → Operating mode = SG3 in Diagnose
2.	Zet uit → Operating mode = SG0/SG2
3.	Failsafe test: HA herstart → switch automatisch uit
4.	Monitor PV-overschot automation → check log in HA
________________________________________
✅ Resultaat
•	PV overschot ja/nee → één HA switch → NIBE SG3
•	NIBE regelt zelf alles: boiler, warmtepomp, dynamische tarieven
•	Failsafe + hysterese voorkomt flapperen en lock-in
________________________________________
1️⃣ Smart Grid Ready aanzetten
Op de NIBE S320 / via myUplink:
•	Menu → Smart Grid → Smart Grid: AAN
Dit activeert de externe SG-sturing.
________________________________________
2️⃣ Wat SG3 mag doen
•	Actie bij SG3 instellen:
o	Extra boiler laden
o	Extra warmtepompverbruik toestaan
•	Dit staat meestal in: Smart Grid → SG3 actie of Load management → SG3
NIBE regelt zelf de verdeling van warmtepomp / boiler / tapwater.
________________________________________
3️⃣ Prijsoptimalisatie / dynamische tarieven
•	NIBE kan zelf de tarieven ophalen (myUplink) → aan laten staan
•	HA hoeft hier niets mee te doen.
________________________________________
4️⃣ Modbus TCP
•	Zorg dat Modbus TCP AAN staat in Communicatie → Modbus TCP
•	IP-adres instellen (vast IP aanbevolen)
•	Slave ID correct instellen (meestal 1)
________________________________________
Samengevat: wat jij instelt op NIBE
Instelling	Waarde / actie
Smart Grid	AAN
SG3 actie	Extra boiler / warmtepomp laden
Prijsoptimalisatie	AAN
Modbus TCP	AAN, IP + slave ID correct
Alles wat A+B beïnvloedt (SG3) wordt nu gestuurd via HA switch, NIBE voert uit volgens zijn eigen logica.

