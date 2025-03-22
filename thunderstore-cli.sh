#!/bin/bash

MODS=$1

GAME_BASE_DIR="Valheim/896660"

# CLI paths
CLI_DIR="Valheim/thunderstore-cli"
TCLI="$CLI_DIR/tcli"
VALHEIM_EXE="$GAME_BASE_DIR/valheim_server.x86_64"

# Verify Thunderstore CLI exists
if [ ! -f "$TCLI" ]; then
    echo "[Thunderstore CLI] ERROR: CLI not found at $TCLI"
    exit 1
fi

# Import Valheim executable if not already imported
if [ ! -d "$CLI_DIR/DataFolder/valheim" ]; then
    echo "[Thunderstore CLI] Importing Valheim server executable..."
    "$TCLI" import-game valheim --exepath "$VALHEIM_EXE"
else
    echo "[Thunderstore CLI] Valheim executable already imported."
fi

# Install mods provided
if [ -n "$MODS" ]; then
    IFS=',' read -ra MOD_ARRAY <<< "$MODS"
    for mod in "${MOD_ARRAY[@]}"; do
        echo "[Thunderstore CLI] Installing mod: $mod"
        "$TCLI" install valheim "$mod"
    done
fi

# Update all mods
echo "[Thunderstore CLI] Updating mods..."
"$TCLI" update valheim

echo "[Thunderstore CLI] Mod installation and updates complete."
