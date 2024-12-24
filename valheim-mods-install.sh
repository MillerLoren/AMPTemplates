### Linux Script ###
#!/bin/bash

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

# Set the flags for whitelist and greylist. First argument passed is the flag for whitelist and second is flag for greylist
whitelist_flag=$1
greylist_flag=$2

# Process each mod in the modlist
while IFS= read -r mod; do
    if [ -z "$mod" ]; then
        continue
    fi

    IFS='-' read -r author package version <<< "$mod"
    plugin_dir="$plugins_dir/$author-$package"

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
    #remove config folder from within plugin directory if it exists
    rm -rf "$plugin_dir/config"

done < "$modlist_file"

# Process each mod in the whitelist and greylist
whitelist_file="./Valheim/896660/mod_whitelist.txt"
whitelist_dir="$base_dir/config/AzuAntiCheat_Whitelist"

if [ "$whitelist_flag" == "true" ]; then
    while IFS= read -r mod; do
        if [ -z "$mod" ]; then
            continue
        fi

        IFS='-' read -r author package version <<< "$mod"
        plugin_whitelist_dir="$whitelist_dir/$author-$package"
        # Check if plugin already exists and version matches
        if [ -f "$plugin_whitelist_dir/manifest.json" ]; then
            existing_version=$(jq -r '.version_number' "$plugin_whitelist_dir/manifest.json")
            if [ "$existing_version" == "$version" ]; then
                echo "$package is already up-to-date. Skipping copy."
                continue
            fi
        fi

        echo "Copying $package ($version)"

        # Remove the plugin from the whitelist directory if it exists and copy the new version
        rm -rf "$plugin_whitelist_dir"
        mkdir -p "$plugin_whitelist_dir"
        cp -r "$plugins_dir/$author-$package"/* "$plugin_whitelist_dir"

    done < "$whitelist_file"
fi

greylist_file="./Valheim/896660/mod_greylist.txt"
greylist_dir="$base_dir/config/AzuAntiCheat_Greylist"

if [ "$greylist_flag" == "true" ]; then
    while IFS= read -r mod; do
        if [ -z "$mod" ]; then
            continue
        fi

        IFS='-' read -r author package version <<< "$mod"
        plugin_greylist_dir="$greylist_dir/$author-$package"
        # Check if plugin already exists and version matches
        if [ -f "$plugin_greylist_dir/manifest.json" ]; then
            existing_version=$(jq -r '.version_number' "$plugin_greylist_dir/manifest.json")
            if [ "$existing_version" == "$version" ]; then
                echo "$package is already up-to-date. Skipping copy."
                continue
            fi
        fi

        echo "Copying $package ($version)"

        # Remove the plugin from the greylist directory if it exists and copy the new version
        rm -rf "$plugin_greylist_dir"
        mkdir -p "$plugin_greylist_dir"
        cp -r "$plugins_dir/$author-$package"/* "$plugin_greylist_dir"
        
    done < "$greylist_file"
fi

# Loop through the whitelist, greylist, and modlist directories and remove any plugins that are not in the lists
for dir in "$whitelist_dir" "$greylist_dir" "$plugins_dir"; do
    for plugin in "$dir"/*; do
        if [ ! -d "$plugin" ]; then
            continue
        fi

        IFS='-' read -r author package <<< "$(basename "$plugin")"
        if [ ! -f "$modlist_file" ] || ! grep -q "$author-$package" "$modlist_file"; then
            echo "Removing $author-$package"
            rm -rf "$plugin"
        fi
    done
done

# Clean up temporary files
echo "All mods processed successfully."