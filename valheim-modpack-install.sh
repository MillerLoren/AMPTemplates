### Linux Script ###
#!/bin/bash

# Ensure script exits on errors
set -e

# Check for input parameter
if [ -z "$1" ]; then
    echo "Usage: $0 <package-name>"
    exit 1
fi

# Parse the input parameter
IFS='-' read -r author package version <<< "$1"

echo "Processing package: Author=$author, Package=$package, Version=$version"

# Construct the download URL
base_url="https://thunderstore.io/package/download"
download_url="$base_url/$author/$package/$version/"

# Define paths
base_dir="Valheim/896660/BepInEx"
config_dir="$base_dir/config"
plugins_dir="$base_dir/plugins"

echo "Downloading $download_url..."
# Create necessary directories
mkdir -p "$config_dir" "$plugins_dir"

# Download and extract main package
wget -q -O main_package.zip "$download_url"
unzip -o main_package.zip -d /tmp/main_package
rm -f main_package.zip

# Merge the config folder
cp -r /tmp/main_package/config/* "$config_dir" 2>/dev/null || true

# Remove existing plugins folder and recreate it
rm -rf "$plugins_dir"
mkdir -p "$plugins_dir"

# Read and process dependencies from manifest.json
manifest_path="/tmp/main_package/manifest.json"
echo "Reading dependencies from $manifest_path..."

if [ -f "$manifest_path" ]; then
    dependencies=$(jq -r '.dependencies[]' "$manifest_path")

    for dep in $dependencies; do
        IFS='-' read -r dep_author dep_package dep_version <<< "$dep"
        dep_url="$base_url/$dep_author/$dep_package/$dep_version/"

        echo "Downloading dependency: $dep ($dep_url)"
        dep_plugin_dir="$plugins_dir/$dep_package"
        mkdir -p "$dep_plugin_dir"

        wget -q -O dependency.zip "$dep_url"
        unzip -o dependency.zip -d "$dep_plugin_dir"
        rm -f dependency.zip
    done
else
    echo "manifest.json not found or no dependencies listed."
fi

# Clean up temporary files
rm -rf /tmp/main_package

echo "Done!"