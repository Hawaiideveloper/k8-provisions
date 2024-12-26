#!/bin/bash

# Check if cloud-init is installed
if dpkg -l | grep -q cloud-init; then
    echo "cloud-init is installed. Disabling it now..."
else
    echo "cloud-init is not installed. Exiting..."
    exit 1
fi

# Disable cloud-init by creating the cloud-init.disabled file
echo "Disabling cloud-init..."
sudo touch /etc/cloud/cloud-init.disabled

# Mask the cloud-init service
echo "Masking cloud-init service..."
sudo systemctl mask cloud-init

# Regenerate initramfs
echo "Regenerating initramfs..."
sudo update-initramfs -u

# Remove cloud-init data (optional)
echo "Removing cloud-init data..."
sudo rm -rf /var/lib/cloud/

# Reboot confirmation
read -p "Do you want to reboot now? (y/n): " reboot_confirm
if [[ "$reboot_confirm" == "y" || "$reboot_confirm" == "Y" ]]; then
    echo "Rebooting the system..."
    sudo reboot
else
    echo "Reboot skipped. Please reboot the system manually for changes to take effect."
fi

echo "cloud-init has been disabled."
