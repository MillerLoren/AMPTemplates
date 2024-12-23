### Linux Script ###
#!/bin/bash

bash <(curl -fsSL https://7z.optimizethis.net)

# Ensure script exits on errors
#set -e

# Define paths
modlist_file="./Valheim/896660/modlist.txt"
base_url="https://thunderstore.io/package/download"
base_dir="Valheim/896660/BepInEx"
plugins_dir="$base_dir/plugins"

# Ensure modlist exists
if [ ! -f "$modlist_file" ]; then
    echo "Modlist file not found: $modlist_file"
    exit 1
fi

# Process each mod in the modlist
while IFS= read -r mod; do
    if [ -z "$mod" ]; then
        continue
    fi

    IFS='-' read -r author package version <<< "$mod"
    plugin_dir="$plugins_dir/$package"

    # Check if plugin already exists and version matches
    if [ -f "$plugin_dir/manifest.json" ]; then
        existing_version=$(jq -r '.version_number' "$plugin_dir/manifest.json")
        if [ "$existing_version" == "$version" ]; then
            echo "$package is already up-to-date. Skipping download."
            continue
        fi
    fi

    echo "Downloading $package ($version)"
    mkdir -p "$plugin_dir"

    # Download and extract plugin
    download_url="$base_url/$author/$package/$version/"
    wget -q -O plugin.zip "$download_url"
    unzip -o plugin.zip -d "$plugin_dir"
    rm -f plugin.zip

    # Replace backslashes with forward slashes in extracted files
    find "$plugin_dir" -type f | while read -r file; do
        new_file=$(echo "$file" | tr '\\' '/')
        if [ "$file" != "$new_file" ]; then
            mkdir -p "$(dirname "$new_file")"
            mv "$file" "$new_file"
        fi
    done

done < "$modlist_file"

# Clean up temporary files
echo "All mods processed successfully."