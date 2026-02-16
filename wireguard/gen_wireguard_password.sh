#!/bin/bash
# Script om een bcrypt hash te genereren voor WireGuard GUI wachtwoord

if [ -z "$1" ]; then
  echo "Gebruik: $0 <nieuw_wachtwoord>"
  exit 1
fi

HASH=$(htpasswd -bnBC 12 admin "$1" | cut -d: -f2)
echo "PASSWORD_HASH=$HASH"
echo "Plak deze regel in je docker-compose.yaml bij de environment variabelen."
