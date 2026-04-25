Docker Storage Migratie Gids: Odroid N2+
Status: Voltooid (April 2026)

Doel: Oplossen van "Double Storage" verbruik op een 16GB eMMC/SD-kaart.

# 1. Inleiding
Op systemen met een oudere configuratie of een specifieke kernel-setup (zoals de Odroid 6.1 kernel), gebruikt Docker vaak de legacy overlayfs driver. Dit veroorzaakt een groot probleem: Docker en de onderliggende Containerd-service delen geen data-layers. Hierdoor wordt elke image in feite twee keer opgeslagen. Op een beperkte schijf van 16GB resulteert dit in een kritiek schijfgebruik van >90%, wat leidt tot crashes en falende updates.

Door beide services te migreren naar overlay2, dwingen we deduplicatie af en winnen we meerdere gigabytes aan ruimte terug.

# 2. Voorbereiding (Cleanup)
Voordat de migratie begint, moet er een buffer aan vrije ruimte zijn om commando's uit te voeren.

## Verwijder oude systeemlogs 

    sudo journalctl --vacuum-time=1d

## Schoon de pakket-cache van Ubuntu op

    sudo apt-get clean
    sudo apt-get autoremove --purge

# 3. Stappenplan voor Migratie

## Stap 1: Volledige stop van services
Docker heeft een 'socket' die de service automatisch herstart bij activiteit. Deze moet samen met de main service en containerd gestopt worden:

    sudo systemctl stop docker.socket
    sudo systemctl stop docker
    sudo systemctl stop containerd

Check de status met systemctl status docker om te bevestigen dat alles 'inactive (dead)' is.

## Stap 2: Docker configureren (overlay2)

Zorg dat de Docker daemon expliciet de juiste driver gebruikt.
Maak of bewerk het bestand: sudo nano /etc/docker/daemon.json

    {
      "storage-driver": "overlay2"
    }

## Stap 3: Containerd configureren (De missende schakel)

Containerd moet op dezelfde 'snapshotter' staan als Docker om data te kunnen delen.

Genereer een standaard configuratie (indien deze niet bestaat):

    containerd config default | sudo tee /etc/containerd/config.toml

Bewerk het bestand: 
  
    sudo nano /etc/containerd/config.toml

Zoek naar de regel: snapshotter = "overlayfs"

Verander dit naar: snapshotter = "overlay2"

## Stap 4: Oude data fysiek verwijderen

Dit is de stap waarbij de gigabytes daadwerkelijk vrijkomen. We verwijderen de oude, inefficiënte mappen:

Bash

    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd

# 4. Herstart en Verificatie

Start de services weer op:

    sudo systemctl start containerd
    sudo systemctl start docker.socket
    sudo systemctl start docker

Haal je containers opnieuw op (bijv. Home Assistant):

    cd ~/HomeAssistant
    docker compose pull
    docker compose up -d

Controleer het resultaat:

Driver check:

    docker info | grep Storage (Moet overlay2 zijn).

Schijfruimte: 

    df -h 
    
Het verbruik zou nu rond de 65-70% moeten liggen in plaats van 94%.

# 5. Onderhoudstips voor 16GB Opslag

Database pruning: Beperk de recorder history in Home Assistant naar 7 dagen om de .db file klein te houden.

Image Pruning: Draai periodiek docker image prune -a om ongebruikte oude versies van images te verwijderen.

Backups: Verplaats .tar backups van Home Assistant naar een externe locatie (Google Drive/Samba) en bewaar er maximaal één lokaal.