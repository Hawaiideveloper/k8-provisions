#!/usr/bin/env python3

import os
import subprocess
import yaml

# Configuration
adapters = ["ens34", "ens35", "ens36"]  # List of network adapters to configure
config_file = "/etc/netplan/01-netcfg.yaml"  # Path to the netplan configuration file


def run_command(command):
    """
    Runs a shell command and returns its output.
    Handles errors if the command fails.
    """
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running command '{' '.join(command)}': {e.stderr.strip()}")
        return None


def get_adapter_info(adapter, primary=False):
    """
    Retrieves the IP address, prefix, gateway (if primary), and DNS settings for a network adapter.
    """
    try:
        # Get the IP address and CIDR notation
        ip_cidr = run_command(["ip", "-o", "-4", "addr", "show", "dev", adapter])
        if not ip_cidr:
            raise ValueError(f"Failed to retrieve IP for adapter {adapter}")

        ip_cidr = ip_cidr.split()[3]
        ip, prefix = ip_cidr.split('/')

        # Get the gateway only for the primary adapter
        gateway = None
        if primary:
            gateway_info = run_command(["ip", "route", "show", "dev", adapter, "default"])
            gateway = gateway_info.split()[2] if gateway_info else None

        # Get DNS servers from /etc/resolv.conf
        dns = []
        with open("/etc/resolv.conf") as resolv:
            for line in resolv:
                if line.startswith("nameserver"):
                    dns.append(line.split()[1])

        return {"ip": ip, "prefix": prefix, "gateway": gateway, "dns": dns}
    except Exception as e:
        print(f"Error retrieving information for adapter {adapter}: {e}")
        return None


def write_netplan_config(adapters_info, file_path):
    """
    Writes the netplan configuration file using the collected adapter information.
    """
    try:
        netplan_config = {
            "network": {
                "version": 2,
                "renderer": "networkd",
                "ethernets": {},
            }
        }

        for adapter, info in adapters_info.items():
            if info:
                netplan_config["network"]["ethernets"][adapter] = {
                    "addresses": [f"{info['ip']}/{info['prefix']}"]
                }
                # Add default route for the primary adapter
                if info['gateway']:
                    netplan_config["network"]["ethernets"][adapter]["routes"] = [
                        {"to": "0.0.0.0/0", "via": info['gateway']}
                    ]
                # Add DNS servers if available
                if info['dns']:
                    netplan_config["network"]["ethernets"][adapter]["nameservers"] = {
                        "addresses": info['dns']
                    }

        # Write the netplan configuration to the file
        with open(file_path, "w") as f:
            yaml.dump(netplan_config, f, default_flow_style=False)

        print(f"Netplan configuration written to {file_path}")
    except Exception as e:
        print(f"Error writing netplan configuration: {e}")


def apply_netplan_config():
    """
    Applies the netplan configuration using the `netplan apply` command.
    """
    try:
        # Fix file permissions to avoid warnings
        os.chmod(config_file, 0o600)

        subprocess.run(["sudo", "netplan", "apply"], check=True)
        print("Netplan configuration applied successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error applying netplan configuration: {e.stderr.strip()}")


def main():
    """
    Main function to gather adapter information, write netplan configuration, and apply it.
    """
    if os.geteuid() != 0:
        print("This script must be run as root. Please try again with 'sudo'.")
        return

    adapters_info = {}

    for i, adapter in enumerate(adapters):
        print(f"Processing adapter: {adapter}")
        # Only the first adapter is marked as primary for the default route
        info = get_adapter_info(adapter, primary=(i == 0))
        if info:
            print(f"Adapter {adapter}: {info}")
        adapters_info[adapter] = info

    # Write the netplan configuration
    write_netplan_config(adapters_info, config_file)

    # Apply the netplan configuration
    apply_netplan_config()


if __name__ == "__main__":
    main()
