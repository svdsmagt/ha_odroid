#!/bin/bash
# Home Assistant database cleanup script

echo "=== Home Assistant Database Cleanup ==="
echo "$(date): Starting database cleanup"

# Database sizes before cleanup
echo "Database sizes BEFORE cleanup:"
du -sh /home/odroid/HomeAssistant/homeassistant/config/home-assistant_v2.db* 2>/dev/null

# Call HA service to purge old data (keep only 5 days)
echo "Calling recorder.purge service..."
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"keep_days": 5, "repack": true}' \
  http://localhost:8123/api/services/recorder/purge

sleep 10

# Database sizes after cleanup
echo "Database sizes AFTER cleanup:"
du -sh /home/odroid/HomeAssistant/homeassistant/config/home-assistant_v2.db* 2>/dev/null

# If database is still > 50MB, warn
DB_SIZE=$(du -s /home/odroid/HomeAssistant/homeassistant/config/home-assistant_v2.db | cut -f1)
if [ "$DB_SIZE" -gt 51200 ]; then
    echo "WARNING: Database is still large (>50MB). Consider reducing keep_days further."
fi

echo "$(date): Database cleanup completed"