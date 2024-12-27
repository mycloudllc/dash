#!/bin/bash

# Function to enable DAC overlay
enable_overlay() {
    local overlay_name=$1
    local config_file="/boot/firmware/config.txt"
    
    echo "Enabling $overlay_name overlay..."
    
    # Check if the overlay is already in the config file
    if grep -q "$overlay_name" "$config_file"; then
        echo "$overlay_name is already enabled in $config_file"
    else
        # Append the overlay to config.txt
        echo "dtoverlay=$overlay_name" | sudo tee -a $config_file > /dev/null
        echo "$overlay_name has been added to $config_file"
    fi
}

# Prompt the user for the DAC overlay name
echo "Please enter the name of the DAC overlay you want to enable (e.g., 'hifiberry-dac', 'justboom-dac'):"
read -p "Overlay name: " overlay_name

# Validate input
if [[ -z "$overlay_name" ]]; then
    echo "No overlay name provided. Exiting."
    exit 1
fi

# Call the function to enable the overlay
enable_overlay $overlay_name

# Inform the user about reboot
echo "The overlay has been enabled. Please reboot your Raspberry Pi for the changes to take effect."
