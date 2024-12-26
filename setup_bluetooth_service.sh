#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit
fi

# Check if bluez-tools is installed
echo "Checking if bluez-tools is installed..."
if ! dpkg -l | grep -q bluez-tools; then
  echo "bluez-tools is not installed. Installing..."
  apt-get update
  apt-get install -y bluez-tools
  if [ $? -ne 0 ]; then
    echo "Failed to install bluez-tools. Exiting."
    exit 1
  fi
else
  echo "bluez-tools is already installed."
fi

# Create the /etc/bluetooth directory if it doesn't exist
BLUETOOTH_DIR="/etc/bluetooth"
echo "Creating directory $BLUETOOTH_DIR if it doesn't exist..."
mkdir -p "$BLUETOOTH_DIR"

# Create the pin.conf file with the specified content
PINS_FILE="$BLUETOOTH_DIR/pin.conf"
echo "Creating $PINS_FILE with default pin..."
echo "* * 4321" > "$PINS_FILE"
if [ $? -ne 0 ]; then
  echo "Failed to create or write to $PINS_FILE. Exiting."
  exit 1
fi
echo "pin.conf file created successfully."

# Create a systemd service file for blue_agent
SERVICE_FILE="/etc/systemd/system/blue_agent.service"
echo "Creating systemd service file at $SERVICE_FILE..."
cat <<EOL > "$SERVICE_FILE"
[Unit]
Description=Bluetooth Auth Agent
After=bluetooth.service
PartOf=bluetooth.service

[Service]
Type=simple
ExecStart=/usr/bin/bt-agent -c NoInputNoOutput -p /etc/bluetooth/pin.conf
ExecStartPost=/bin/sleep 1
ExecStartPost=/bin/hciconfig hci0 sspmode 0
ExecStartPost=/bin/bash -c 'echo -e "discoverable on\n" | bluetoothctl'

[Install]
WantedBy=bluetooth.target
EOL

if [ $? -ne 0 ]; then
  echo "Failed to create systemd service file. Exiting."
  exit 1
fi

# Reload systemd daemon and enable the service
echo "Reloading systemd daemon and enabling blue_agent service..."
systemctl daemon-reload
systemctl enable blue_agent.service

# Prompt to start the service
echo "Would you like to start the blue_agent service now? (y/n)"
read -r RESPONSE
if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
  echo "Starting the blue_agent service..."
  systemctl start blue_agent.service
  if [ $? -eq 0 ]; then
    echo "blue_agent service started successfully."
  else
    echo "Failed to start blue_agent service."
  fi
else
  echo "You can start the service later by running:"
  echo "sudo systemctl start blue_agent.service"
fi

echo "Setup complete."
