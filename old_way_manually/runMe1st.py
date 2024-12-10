#!/usr/bin/env python3

import os
import subprocess
import yaml

# Configuration
adapters = ["ens34", "ens35", "ens36"]  # List of network adapters to configure
config_file = "/etc/netplan/01-netcfg.yaml"  # Path to the netplan configuration file
hostname = "kubernetes-node"  # Desired hostname for the Kubernetes node
routes_to_remove = {
    "ens35": "192.168.79.1",
    "ens36": "192.168.69.1"
}

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

def disable_swap():
    """
    Disables swap memory to comply with Kubernetes requirements.
    """
    print("Disabling swap...")
    run_command(['swapoff', '-a'])
    with open("/etc/fstab", "r+") as fstab:
        lines = fstab.readlines()
        fstab.seek(0)
        for line in lines:
            if "swap" not in line:
                fstab.write(line)
        fstab.truncate()
    print("Swap has been disabled.")

def set_hostname():
    """
    Sets the hostname of the machine.
    """
    print("Setting hostname...")
    run_command(['hostnamectl', 'set-hostname', hostname])
    with open("/etc/hosts", "a") as hosts_file:
        hosts_file.write(f"127.0.1.1 {hostname}\n")
    print(f"Hostname set to {hostname}")

def update_system():
    """
    Updates all system packages to the latest versions.
    """
    print("Updating system packages...")
    run_command(['apt', 'update'])
    run_command(['apt', 'upgrade', '-y'])
    print("System packages have been updated.")

def configure_firewall():
    """
    Configures the UFW firewall to allow necessary Kubernetes ports.
    """
    print("Configuring firewall for Kubernetes ports...")
    k8s_ports = [
        "6443",    # Kubernetes API server
        "2379:2380",  # etcd server client API
        "10250",   # Kubelet API
        "10255",   # Read-only Kubelet API
        "30000:32767"  # NodePort Services
    ]
    for port in k8s_ports:
        run_command(['ufw', 'allow', port + '/tcp'])
    run_command(['ufw', 'enable'])
    print("Firewall configured for Kubernetes ports.")

def remove_default_routes():
    """
    Removes specific default routes as required for Kubernetes network setup.
    """
    print("Removing specific default routes...")
    for adapter, gateway in routes_to_remove.items():
        command = ['ip', 'route', 'del', 'default', 'via', gateway, 'dev', adapter]
        if run_command(command) is not None:
            print(f"Removed default route via {gateway} on {adapter}")
        else:
            print(f"Failed to remove route via {gateway} on {adapter} or it did not exist.")

def main():
    """
    Main function to setup the machine for Kubernetes.
    """
    if os.geteuid() != 0:
        print("This script must be run as root. Please try again with 'sudo'.")
        return

    update_system()  # Update system packages
    set_hostname()  # Set system hostname
    disable_swap()  # Disable swap
    configure_firewall()  # Setup firewall
    remove_default_routes()  # Remove specified default routes

    # Networking configuration (Netplan)
    adapters_info = {}
    for i, adapter in enumerate(adapters):
        print(f"Processing adapter: {adapter}")
        # Only the first adapter is marked as primary for the default route
        info = get_adapter_info(adapter, primary=(i == 0))
        if info:
            print(f"Adapter {adapter}: {info}")
        adapters_info[adapter] = info

    write_netplan_config(adapters_info, config_file)
    apply_netplan_config()

if __name__ == "__main__":
    main()
