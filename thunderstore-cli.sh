#!/bin/bash

# Variables passed from AMP (CLI Version and Mod List)
CLI_VERSION=$1
MODS=$2
BASE_DIR=$3

# Directories
CLI_DIR="thunderstore-cli"
CLI_ARCHIVE="tcli-$CLI_VERSION-linux-x64.tar.gz"
CLI_URL="https://github.com/thunderstore-io/thunderstore-cli/releases/download/$CLI_VERSION/$CLI_ARCHIVE"

echo "[Thunderstore CLI] Installing Thunderstore CLI v$CLI_VERSION..."

# Create CLI directory if it doesn't exist
mkdir -p $CLI_DIR
cd $CLI_DIR

# Remove existing archive if present
rm -f $CLI_ARCHIVE

# Download the Thunderstore CLI
wget $CLI_URL
if [ $? -ne 0 ]; then
    echo "[Thunderstore CLI] Failed to download Thunderstore CLI from $CLI_URL"
    exit 1
fi

# Extract the CLI
tar -xzvf $CLI_ARCHIVE
if [ $? -ne 0 ]; then
    echo "[Thunderstore CLI] Failed to extract Thunderstore CLI archive"
    exit 1
fi

# echo the contents of the directory
ls -la

# Move the CLI from thunderstore-cli/tcli-$CLI_VERSION-linux-x64 to base directory
mv tcli-$CLI_VERSION-linux-x64/tcli ../tcli
mv tcli-$CLI_VERSION-linux-x64/tcli-bepinex-installer ../tcli-bepinex-installer


# Remove downloaded archive
rm -f $CLI_ARCHIVE

# Ensure CLI is executable
chmod +x tcli

echo "[Thunderstore CLI] Thunderstore CLI v$CLI_VERSION installed successfully."

./tcli import-game valheim --exepath $BASE_DIR/valheim_server.x86_64

# Install mods if provided
if [ -n "$MODS" ]; then
    IFS=',' read -ra MOD_ARRAY <<< "$MODS"
    for mod in "${MOD_ARRAY[@]}"; do
        echo "[Thunderstore CLI] Installing mod: $mod"
        ./tcli install valheim "$mod"
    done
fi

echo "[Thunderstore CLI] Mods installation and updates completed."
