# Home Assistant Setup & Optimalisatie Stappen

## Status: Container is gestart maar configuratie moet nog gebeuren

### Datum: 15 februari 2026
### Installatie gepland: Maart 2026

---

## 1. Eerste setup na installatie (via HA Web UI)

### Basis configuratie
1. Open http://localhost:8123
2. Voltooi de initiële setup wizard
3. Maak admin account aan

### Database & Storage optimalisatie
1. **Settings > System > Storage**
   - Stel **Purge keep days** in op **5 dagen** (standaard is 10)
   - **Purge interval** op **1 dag**
   - Dit bespaart heel veel schijfruimte!

2. **Settings > System > Logs**
   - Log level instellen op **Warning** of **Error**
   - Specifieke integrations logging uitschakelen waar mogelijk

---

## 2. Database automatisch opruimen (BELANGRIJK!)

### Via Automations (Settings > Automations & Scenes > Automations):
Maak nieuwe automation aan:

**Naam:** Daily Database Cleanup
**Trigger:** Time - 04:00:00 (dagelijks)
**Action:** Call service `recorder.purge`
```yaml
service: recorder.purge
data:
  keep_days: 5
  repack: true
```

### Handmatig opruimen via Developer Tools:
1. **Settings > Developer Tools > Services**
2. Service: `recorder.purge`
3. Service Data:
```json
{
  "keep_days": 5,
  "repack": true
}
```

---

## 3. Configuratie bestanden aanpassen (optioneel)

### Als je access hebt tot configuration.yaml:
Voeg toe om database verder te beperken:

```yaml
# Beperk database grootte  
recorder:
  purge_keep_days: 5        # Bewaar slechts 5 dagen data
  purge_interval: 1         # Dagelijks opruimen
  commit_interval: 30       # Minder frequent wegschrijven
  exclude:
    domains:
      - automation
      - script
      - scene
    entities:
      - sun.sun               # Zon staat hoeft niet opgeslagen
      - weather.*             # Weer data niet bewaren

# Beperk logbook
logbook:
  exclude:
    domains:
      - automation
      - script
    entities:
      - sun.sun

# Beperk history
history:
  exclude:
    domains:
      - automation  
    entities:
      - sun.sun
      - weather.*

# Logging configuratie
logger:
  default: warning          # Alleen warnings en errors
  logs:
    homeassistant.components.recorder: warning
    homeassistant.components.zeroconf: warning
    homeassistant.components.discovery: error
```

---

## 4. Problematische integraties oplossen

### DSMR Integration Error:
**Settings > Integrations > DSMR**
- Verwijder deze integration of disable als je geen slimme meter USB device hebt

### RPi Power Integration Error:
**Settings > Integrations > Raspberry Pi Power Supply Checker**  
- Verwijder deze integration (werkt niet op non-RPi hardware)

### Via integration settings:
1. Settings > Devices & Services
2. Zoek naar "DSMR" en "Raspberry Pi Power" 
3. Klik op de 3 puntjes > Delete/Remove

---

## 5. Periodiek onderhoud

### Wekelijks:
- Database grootte controleren: `du -sh config/home-assistant_v2.db*`
- Als database > 50MB is: handmatig purge uitvoeren

### Maandelijks:
- Docker images opruimen: `docker system prune -a -f` (kan 3-4GB vrijmaken!)
- Oude backups verwijderen indien aanwezig

### Monitoring commando's:
```bash
# Schijfruimte controleren
df -h /

# Database grootte
du -sh /home/odroid/HomeAssistant/homeassistant/config/home-assistant_v2.db*

# Docker resource gebruik  
docker system df

# Container stats
docker stats homeassistant
```

---

## 6. Script voor database cleanup (al aanwezig)

**Locatie:** `/home/odroid/HomeAssistant/db-cleanup.sh`

**Gebruik:**
```bash
# Manual run (vereist HA API token eerst)
./db-cleanup.sh

# In crontab zetten voor automatisch (optioneel):
# 0 4 * * * /home/odroid/HomeAssistant/db-cleanup.sh >> /tmp/ha-cleanup.log 2>&1
```

**Let op:** Script vereist API token configuratie na eerste HA setup!

---

## 7. Huidige Docker configuratie (al geconfigureerd)

✅ **Logging beperkt:** 20MB totaal  
✅ **Warning level logging**  
✅ **Supervisor errors opgelost**  
✅ **mDNS poort uitgeschakeld** (poort 5353)  
✅ **Health monitoring** actief  

---

## 8. Na 1 maand gebruik controleren

### Storage usage verwachtingen:
- **Database:** 5-20MB (met 5 dagen geschiedenis)
- **Config totaal:** 10-50MB  
- **Container logs:** Max 20MB
- **Docker images:** 1-4GB

### Als ruimte nog krap is:
1. Purge keep days verder verlagen naar 3 dagen
2. Meer entities excluden van recorder
3. Specifieke integrations uitschakelen die veel data genereren

---

## 9. Belangrijke URLs & Commands

**Home Assistant Web:** http://localhost:8123  
**Container logs:** `docker logs homeassistant`  
**Restart container:** `docker compose -f HomeAssistant/homeassistant/docker-compose.yaml restart`  
**Stop/start:** `docker compose -f HomeAssistant/homeassistant/docker-compose.yaml down/up -d`

---

## ⚠️ Belangrijke opmerkingen:

1. **Eerste maand:** Monitor database grootte wekelijks
2. **eMMC bescherming:** Houd altijd >1GB vrije ruimte over  
3. **Backup strategie:** Overweeg externe backup voor belangrijke config
4. **Updates:** Container auto-update disabled voor stabiliteit

**Huidige vrije ruimte bij setup: 4.2GB van 15GB**