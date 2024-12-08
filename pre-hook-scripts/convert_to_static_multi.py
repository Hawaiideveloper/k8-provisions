#!/usr/bin/env python3


import os
import subprocess
import yaml
from pathlib import Path

# Configuration
adapters = ["ens33", "ens34", "ens35"]  # List of network adapters to configure (replace with your actual adapter names)
config_file = "/etc/netplan/01-netcfg.yaml"  # Path to the netplan configuration file


def run_command(command):
    """
    Runs a shell command and returns its output.
    Handles errors if the command fails.
    """
    try:
        # Run the command and capture the output
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        return result.stdout.strip()  # Return the standard output as a stripped string
    except subprocess.CalledProcessError as e:
        # Handle any error during command execution and print the error message
        print(f"Error running command '{' '.join(command)}': {e.stderr.strip()}")
        return None  # Return None if the command fails


def get_adapter_info(adapter):
    """
    Retrieves the IP address, prefix, gateway, and DNS settings for a network adapter.
    """
    try:
        # Get the IP address and CIDR notation for the adapter
        ip_cidr = run_command(["ip", "-o", "-4", "addr", "show", "dev", adapter])
        if not ip_cidr:
            raise ValueError(f"Failed to retrieve IP for adapter {adapter}")  # Raise an error if no IP is found

        # Extract the IP address and prefix (e.g., "192.168.1.2/24")
        ip_cidr = ip_cidr.split()[3]
        ip, prefix = ip_cidr.split('/')

        # Get the default gateway for the adapter
        gateway = run_command(["ip", "route", "show", "dev", adapter, "default"])
        gateway = gateway.split()[2] if gateway else None  # Extract the gateway IP if available

        # Get the DNS servers from /etc/resolv.conf
        dns = []
        with open("/etc/resolv.conf") as resolv:
            for line in resolv:
                if line.startswith("nameserver"):  # Look for lines starting with "nameserver"
                    dns.append(line.split()[1])  # Append the DNS server IP to the list

        # Return the collected information as a dictionary
        return {"ip": ip, "prefix": prefix, "gateway": gateway, "dns": dns}
    except Exception as e:
        # Handle any errors and print a message
        print(f"Error retrieving information for adapter {adapter}: {e}")
        return None  # Return None if there was an issue


def write_netplan_config(adapters_info, file_path):
    """
    Writes the netplan configuration file using the collected adapter information.
    """
    try:
        # Create a dictionary for the netplan configuration
        netplan_config = {
            "network": {
                "version": 2,  # Netplan version
                "renderer": "networkd",  # Specify the renderer (networkd for systemd)
                "ethernets": {},  # Placeholder for adapter configurations
            }
        }

        # Loop through each adapter and add its configuration
        for adapter, info in adapters_info.items():
            if info:  # Only add configurations for adapters with valid information
                netplan_config["network"]["ethernets"][adapter] = {
                    "addresses": [f"{info['ip']}/{info['prefix']}"]  # Add IP address with prefix
                }
                if info['gateway']:  # Add gateway if available
                    netplan_config["network"]["ethernets"][adapter]["gateway4"] = info['gateway']
                if info['dns']:  # Add DNS servers if available
                    netplan_config["network"]["ethernets"][adapter]["nameservers"] = {
                        "addresses": info['dns']
                    }

        # Write the netplan configuration to the specified file
        with open(file_path, "w") as f:
            yaml.dump(netplan_config, f, default_flow_style=False)  # Use YAML to format the configuration

        print(f"Netplan configuration written to {file_path}")
    except Exception as e:
        # Handle any errors during file writing
        print(f"Error writing netplan configuration: {e}")


def apply_netplan_config():
    """
    Applies the netplan configuration using the `netplan apply` command.
    """
    try:
        subprocess.run(["sudo", "netplan", "apply"], check=True)  # Apply the netplan configuration
        print("Netplan configuration applied successfully.")
    except subprocess.CalledProcessError as e:
        # Handle any errors during netplan apply
        print(f"Error applying netplan configuration: {e.stderr.strip()}")


def main():
    """
    Main function to gather adapter information, write netplan configuration, and apply it.
    """
    # Check if script is run as root
    if os.geteuid() != 0:  # Check if the effective user ID is not 0 (root)
        print("This script must be run as root. Please try again with 'sudo'.")
        return

    adapters_info = {}  # Dictionary to store information for each adapter

    for adapter in adapters:
        print(f"Processing adapter: {adapter}")
        info = get_adapter_info(adapter)  # Retrieve information for the adapter
        if info:
            print(f"Adapter {adapter}: {info}")  # Print the collected information
        adapters_info[adapter] = info  # Add the information to the dictionary

    # Write the collected information to the netplan configuration file
    write_netplan_config(adapters_info, config_file)

    # Apply the netplan configuration
    apply_netplan_config()


if __name__ == "__main__":
    # Entry point of the script
    main()

