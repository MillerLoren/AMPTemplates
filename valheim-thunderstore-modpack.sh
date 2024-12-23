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

# Define base paths and URLs
api_url="https://thunderstore.io/api/experimental/package/$author/$package/$version/"
base_dir="Valheim/896660/BepInEx"
config_dir="$base_dir/config"
plugins_dir="$base_dir/plugins"

# Create necessary directories
mkdir -p "$config_dir" "$plugins_dir"

# Fetch package data using the API
echo "Fetching package data from $api_url..."
package_data=$(curl -s "$api_url")

# Extract download URL
main_download_url=$(echo "$package_data" | jq -r '.full_version.download_url')

echo "Downloading main package from $main_download_url..."
# Download and extract main package
wget -q -O main_package.zip "$main_download_url"
unzip -o main_package.zip 'config/*' -d /tmp/main_package
rm -f main_package.zip

# Merge the config folder
cp -r /tmp/main_package/config/* "$config_dir" 2>/dev/null || true
rm -rf /tmp/main_package

# Remove existing plugins folder and recreate it
rm -rf "$plugins_dir"
mkdir -p "$plugins_dir"

# Process dependencies
echo "Processing dependencies..."
echo "$package_data" | jq -r '.full_version.dependencies[]' | while read dep; do
    dep_author=$(echo "$dep" | cut -d'-' -f1)
    dep_package=$(echo "$dep" | cut -d'-' -f2)
    dep_version=$(echo "$dep" | cut -d'-' -f3)
    
    dep_api_url="https://thunderstore.io/api/experimental/package/$dep_author/$dep_package/$dep_version/"
    echo "Fetching dependency data from $dep_api_url..."
    dep_data=$(curl -s "$dep_api_url")
    dep_download_url=$(echo "$dep_data" | jq -r '.full_version.download_url')

    echo "Downloading dependency: $dep ($dep_download_url)"
    dep_plugin_dir="$plugins_dir/$dep_package"
    mkdir -p "$dep_plugin_dir"

    wget -q -O dependency.zip "$dep_download_url"
    unzip -o dependency.zip -d "$dep_plugin_dir"
    rm -f dependency.zip

done

echo "Done!"