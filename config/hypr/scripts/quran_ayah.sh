#!/bin/bash

# Fetch a random Ayah, using a timestamp "cache buster" to force a fresh response
JSON=$(curl -s "https://api.alquran.cloud/v1/ayah/random/ar.quran-uthmani?t=$(date +%s)")

# Parse the JSON data
AYAH=$(echo "$JSON" | jq -r '.data.text')
SURAH=$(echo "$JSON" | jq -r '.data.surah.name')
NUMBER=$(echo "$JSON" | jq -r '.data.numberInSurah')

# Output the formatted text for Hyprlock
echo "$AYAH"
echo "﴿ $SURAH : $NUMBER ﴾"
