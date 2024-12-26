#!/bin/bash

# Default values
DEFAULT_SSID="DASH"
DEFAULT_PASSWORD="1234567890"
DEFAULT_OPENAUTO_CONFIG_PATH="$HOME/openauto.ini"  # Default location in user's home directory

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ASCII Art Header
echo -e "${BLUE}========================================="
echo -e "🚀 ${YELLOW}Raspberry Pi Hotspot Creator 🚀${NC}"
echo -e "${BLUE}=========================================${NC}\n"

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root. Re-running with sudo...${NC}"
    sudo "$0" "$@"
    exit
fi

# Prompt for Wi-Fi name (SSID)
echo -e "${GREEN}Enter Wi-Fi name (SSID) or press Enter to use the default ('$DEFAULT_SSID'):${NC}"
read -r SSID
SSID=${SSID:-$DEFAULT_SSID}

# Prompt for Wi-Fi password
echo -e "${GREEN}Enter Wi-Fi password or press Enter to use the default ('$DEFAULT_PASSWORD'):${NC}"
read -r PASSWORD
PASSWORD=${PASSWORD:-$DEFAULT_PASSWORD}

# Ask if the user wants connection sharing
echo -e "${GREEN}Do you want to enable connection sharing? (yes/no, default: no):${NC}"
read -r SHARING
SHARING=${SHARING:-no}

# Ask if the user wants to enable AutoStart
echo -e "${GREEN}Do you want the hotspot to start automatically on boot? (yes/no, default: no):${NC}"
read -r AUTOSTART
AUTOSTART=${AUTOSTART:-no}

# Prompt for custom openauto.ini location
echo -e "${GREEN}Enter the path to openauto.ini or press Enter to use the default ('$DEFAULT_OPENAUTO_CONFIG_PATH'):${NC}"
read -r OPENAUTO_CONFIG_PATH
OPENAUTO_CONFIG_PATH=${OPENAUTO_CONFIG_PATH:-$DEFAULT_OPENAUTO_CONFIG_PATH}

# For hotspot/wifi to be enabled, country code is needed
echo -e "${GREEN}What is your 2 digit country code to enable wifi? (default: US):${NC}"
read -r COUNTRY_CODE
COUNTRY_CODE=${COUNTRY_CODE:US}

# Configure the hotspot
sudo raspi-config nonint do_wifi_country "$COUNTRY_CODE"
echo -e "${BLUE}Configuring hotspot...${NC}"
sudo nmcli device wifi hotspot ssid "$SSID" password "$PASSWORD" ifname wlan0

if [ "$SHARING" = "yes" ]; then
   sudo nmcli connection modify Hotspot ipv4.method shared
else
   sudo nmcli connection modify Hotspot ipv4.method manual
fi

if [ "$AUTOSTART" = "yes" ]; then
   sudo nmcli connection modify Hotspot connection.autoconnect yes
fi

# Simulate loading
echo -n -e "${YELLOW}Activating hotspot${NC}"
for i in {1..3}; do
    echo -n "."
    sleep 0.5
done

# Activate the hotspot
sudo nmcli connection up "$SSID"
echo -e "\n${GREEN}Hotspot activated!${NC}"

# Update the openauto.ini file
echo -e "${BLUE}Updating openauto.ini...${NC}"
if [ -f "$OPENAUTO_CONFIG_PATH" ]; then
    sudo sed -i "s/^SSID=.*/SSID=$SSID/" "$OPENAUTO_CONFIG_PATH"
    sudo sed -i "s/^Password=.*/Password=$PASSWORD/" "$OPENAUTO_CONFIG_PATH"
    echo -e "${GREEN}openauto.ini updated successfully.${NC}"
else
    echo -e "${RED}Warning: openauto.ini file not found at $OPENAUTO_CONFIG_PATH. Please update it manually.${NC}"
fi

# Display the configuration
echo -e "\n${YELLOW}Hotspot Configuration:${NC}"
echo -e "${GREEN}SSID: $SSID${NC}"
echo -e "${GREEN}Password: $PASSWORD${NC}"
if [ "$SHARING" = "yes" ]; then
    echo -e "${GREEN}Connection sharing is enabled.${NC}"
else
    echo -e "${RED}Connection sharing is disabled.${NC}"
fi
if [ "$AUTOSTART" = "yes" ]; then
    echo -e "${GREEN}Hotspot will start automatically on boot.${NC}"
else
    echo -e "${RED}Hotspot will not start automatically on boot.${NC}"
fi

echo -e "\n${BLUE}🎉 Setup complete! Enjoy your hotspot! 🎉${NC}"
