#!/bin/bash

# Define color codes for flair
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# Function to display the menu
display_menu() {
    clear
    echo -e "${BLUE}============================================="
    echo -e "${GREEN}OpenAuto Configuration Script for Raspberry Pi"
    echo -e "${BLUE}============================================="
    echo -e "${YELLOW}1) Set up hotspot for wireless AA"
    echo -e "2) Remove cursor from desktop"
    echo -e "3) Remove taskbar"
    echo -e "4) Disable onboard Bluetooth"
    echo -e "5) Set up custom wallpaper and boot screen."
    echo -e "6) Disable Screen blanking."
    echo -e "7) Switch to x11 from wayland on bookworm (needed for app launcher."
    echo -e "8) Speed up boot and improve stability"
    echo -e "9) Set up brightness control"
    echo -e "10) Set up DAC Hat"
    echo -e "11) Enable experimental bluetooth pin pairing"
    echo -e "0) Exit"
    echo -e "${NC}"
    read -p "Please select an option (0-10): " choice
}

# Function to determine OS version
get_os_version() {
    if grep -q "bookworm" /etc/os-release; then
        echo "bookworm"
    else
        echo "older"
    fi
}

# Get the OS version
os_version=$(get_os_version)

# Function to set up hotspot for wireless AA
setup_hotspot() {
    echo -e "${GREEN}Setting up hotspot for wireless AA...${NC}" 
    # Check if the hotspot.sh script exists in the same directory
    if [ -f "$(dirname "$0")/hotspot.sh" ]; then
        #add executions permissions to hotspot script
        chmod +x $(dirname "$0")/hotspot.sh
        # Call the hotspot.sh script
        bash "$(dirname "$0")/hotspot.sh"
        echo -e "${YELLOW}Hotspot setup complete!${NC}"
    else
        echo -e "${RED}Error: hotspot.sh script not found in the current directory.${NC}"
    fi
}

# Function to remove the cursor from the desktop
remove_cursor() {
    echo -e "${GREEN}Removing cursor from desktop...${NC}"
    # Add commands to hide the cursor
    sed -i -- "s/#xserver-command=X/xserver-command=X -nocursor/" /etc/lightdm/lightdm.conf
    echo -e "${YELLOW}Cursor removed!${NC}"
}

# Function to remove taskbar
remove_taskbar() {
    echo -e "${GREEN}Removing taskbar...${NC}"
    # Create a copy for backup
    sudo cp /usr/bin/lxpanel /usr/bin/lxpanel.backup
    # Disable taskbar in LXDE
    sudo rm -f /usr/bin/lxpanel
    echo -e "${YELLOW}Taskbar removed!${NC}"
}

# Function to disable onboard Bluetooth
disable_bluetooth() {
    echo "Disabling the onboard Bluetooth adapter"
    echo "dtoverlay=disable-bt" >> /boot/config.txt
    echo "blacklist btbcm" >> /etc/modprobe.d/raspi-blacklist.conf
    echo "blacklist hci_uart" >> /etc/modprobe.d/raspi-blacklist.conf
    sudo rfkill unblock bluetooth
    echo -e "${YELLOW}Onboard Bluetooth disabled!${NC}"
}

# Function to set up custom wallpaper and boot screen
setup_wallpaper() {
    echo -e "${GREEN}Setting up custom wallpaper and boot screen...${NC}"
    # Custom wallpaper setup
    export DISPLAY=:0.0
    pcmanfm --set-wallpaper /wallpaper/custom.jpg
    # Boot screen setup
    sudo cp /dash/splash.png /usr/share/plymouth/themes/pix/splash.png
    sudo sed -i '/message_sprite = Sprite();/,/message_sprite.SetImage(my_image);/c\
    message_sprite = Sprite();\
    message_sprite.SetPosition(screen_width * 0.1, screen_height * 0.9, 10000);\
    my_image = Image.Text(text, 1, 1, 1);\
    message_sprite.SetImage(my_image);' /usr/share/plymouth/themes/pix/pix.script
    sudo sed -i 's/$/ logo.nologo vt.global_cursor_default=0/' /boot/cmdline.txt
    echo -e "${YELLOW}Custom wallpaper/boot screen set!${NC}"
}

# Function to speed up boot and improve stability
speed_up_boot() {
    echo -e "${GREEN}Speeding up boot and improving stability...${NC}"
    # Disable unnecessary services or tweak boot config
    # Execute the appropriate command based on the OS version
    if [ "$os_version" = "bookworm" ]; then
        echo "Detected Bookworm. Disabling NetworkManager-wait-online.service..."
        sudo systemctl disable NetworkManager-wait-online.service
    elif [ "$os_version" = "older" ]; then
        echo "Detected older Debian version. Configuring boot wait..."
        sudo raspi-config nonint do_boot_wait 0
    else
        echo "Unsupported OS version or error detecting OS version."
    fi
    sudo systemctl disable avahi-daemon
    echo "dtparam=krnbt" >> /boot/config.txt
    echo -e "${YELLOW}Boot speed improved and stability enhanced!${NC}"
}

# Function to set up brightness control
setup_brightness() {
    FILE=/etc/udev/rules.d/52-dashbrightness.rules
  if [[ ! -f "$FILE" ]]; then
     # udev rules to allow write access to all users for Raspberry Pi 7" Touch Screen
     echo "SUBSYSTEM==\"backlight\", RUN+=\"/bin/chmod 666 /sys/class/backlight/%k/brightness\"" | sudo tee $FILE
     if [[ $? -eq 0 ]]; then
         echo -e "Permissions created\n"
     else
         echo -e "Unable to create permissions\n"
     fi
  else
     echo -e "Rules exists\n"
  fi
}

# Function to set up DAC Hat
setup_dac_hat() {
    echo -e "${GREEN}Setting up audio dac...${NC}"
    
    # Check if the enable-dac-overlay.sh script exists in the same directory
    if [ -f "$(dirname "$0")/enable-dac-overlay.sh" ]; then
        # Call the enable-dac-overlay.sh script
        bash "$(dirname "$0")/enable-dac-overlay.sh"
        echo -e "${YELLOW}Dac setup complete!${NC}"
    else
        echo -e "${RED}Error: enable-dac-overlay.sh script not found in the current directory.${NC}"
    fi
}

# Function to disable screen blanking
disable_blanking() {
    sudo raspi-config nonint do_blanking 1
    echo -e "${YELLOW}Screen Blanking disabled!${NC}"
}

# Function to disable wayland
disable_wayland() {
    sudo raspi-config nonint do_wayland W1
    echo -e "${YELLOW}Wayland has been replaced with X11. You may now use app launcher!${NC}"
}

# Experimental Function to enable bt pin pairing
enable_btpin() {
    sudo setup_bluetooth.sh
    echo -e "${RED}Experimental bluetooth pairing is now enabled and a service has been created. Pin is 4321.${NC}"
    echo -e "${RED}To disable run systemctl disable bt_start.service${NC}"
}
    
# Main loop
while true; do
    display_menu
    case $choice in
        1) setup_hotspot ;;
        2) remove_cursor ;;
        3) remove_taskbar ;;
        4) disable_bluetooth ;;
        5) setup_wallpaper ;;
        5) disable_blanking ;;
        7) disable_wayland ;;
        8) speed_up_boot ;;
        9) setup_brightness ;;
        10) setup_dac_hat ;;
        11) enable_btpin ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid choice! Please select a number between 0 and 11.${NC}" ;;
    esac
    read -p "Press any key to continue..." -n1 -s
done
