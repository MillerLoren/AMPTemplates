### Linux Script ###
#!/bin/bash

# Ensure script exits on errors
set -e

# Define paths
modlist_file="./Valheim/896660/modlist.txt"
base_url="https://thunderstore.io/package/download"
base_dir="Valheim/896660/BepInEx"
plugins_dir="$base_dir/plugins"
temp_dir="/tmp/valheim_mod"

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

    # Extract to temporary directory to handle backslashes
    mkdir -p "$temp_dir"
    unzip -q plugin.zip -d "$temp_dir"

    # Normalize paths and move to the target directory
    find "$temp_dir" -type f | while IFS= read -r file; do
        normalized_path="${file#"$temp_dir/"}"
        normalized_path="${normalized_path//\\/\/}"
        target_path="$plugin_dir/$normalized_path"
        mkdir -p "$(dirname "$target_path")"
        mv "$file" "$target_path"
    done

    # Cleanup
    rm -rf "$temp_dir" plugin.zip

done < "$modlist_file"

# Clean up temporary files
echo "All mods processed successfully."