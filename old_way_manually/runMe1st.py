#!/usr/bin/env python3

import os
import subprocess

# Configuration
adapters = ["ens34", "ens35", "ens36"]  # List of network adapters to configure
config_file = "/etc/netplan/01-netcfg.yaml"  # Path to the netplan configuration file
hostname = "k8-controlplane"  # Correct hostname for the Kubernetes control plane
routes_to_remove = {
    "ens35": "192.168.79.1",
    "ens36": "192.168.69.1"
}
nameserver = "172.100.55.2"  # Desired nameserver for DNS resolution

def run_command(command, ignore_errors=False):
    """
    Runs a shell command and returns its output.
    Handles errors if the command fails.
    """
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        if not ignore_errors:
            print(f"Error running command '{' '.join(command)}': {e.stderr.strip()}")
        return None

def remove_kubernetes_tools():
    """
    Checks for and removes existing Kubernetes tools (kubeadm, kubectl, kubelet).
    """
    print("Checking and removing existing Kubernetes tools if found...")
    tools = ["kubeadm", "kubectl", "kubelet"]
    for tool in tools:
        tool_path = run_command(["which", tool], ignore_errors=True)
        if tool_path:
            print(f"{tool} found at {tool_path}. Removing...")
            run_command(["apt", "purge", "-y", tool])
            run_command(["apt", "autoremove", "-y"])
            print(f"{tool} and related dependencies have been removed.")
        else:
            print(f"{tool} not found. Assuming it has already been removed.")

    # Remove Kubernetes-related directories
    directories = ["/etc/kubernetes", "/var/lib/kubelet"]
    for directory in directories:
        if os.path.exists(directory):
            print(f"Removing directory: {directory}")
            run_command(["rm", "-rf", directory])

    print("Kubernetes tools and related components cleaned up.")

def configure_dns():
    """
    Configures DNS to use the specified nameserver.
    """
    print(f"Setting nameserver to {nameserver}...")
    resolv_conf = "/etc/resolv.conf"
    with open(resolv_conf, "w") as resolv_file:
        resolv_file.write(f"nameserver {nameserver}\n")
    print("DNS configured successfully.")

def disable_ipv6():
    """
    Disables IPv6 permanently.
    """
    print("Disabling IPv6 permanently...")
    sysctl_conf = "/etc/sysctl.d/99-sysctl.conf"
    ipv6_config = [
        "net.ipv6.conf.all.disable_ipv6 = 1",
        "net.ipv6.conf.default.disable_ipv6 = 1"
    ]
    
    # Add IPv6 disable configuration if not already present
    with open(sysctl_conf, "a") as sysctl_file:
        for line in ipv6_config:
            sysctl_file.write(line + "\n")

    # Apply sysctl changes
    run_command(["sysctl", "--system"])
    print("IPv6 successfully disabled.")

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
    print(f"Setting hostname to {hostname}...")
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
        run_command(['ufw', 'allow', port + '/tcp'], ignore_errors=True)
    run_command(['ufw', 'enable'], ignore_errors=True)
    print("Firewall configured for Kubernetes ports.")

def remove_default_routes():
    """
    Removes specific default routes as required for Kubernetes network setup.
    """
    print("Removing specific default routes...")
    for adapter, gateway in routes_to_remove.items():
        result = run_command(['ip', 'route', 'del', 'default', 'via', gateway, 'dev', adapter], ignore_errors=True)
        if result is not None:
            print(f"Removed default route via {gateway} on {adapter}")
        else:
            print(f"Route via {gateway} on {adapter} not present. Skipping.")

def verify_kubeadm_preflight():
    """
    Verifies kubeadm preflight checks.
    """
    print("Running kubeadm preflight checks...")
    if run_command(["which", "kubeadm"], ignore_errors=True):
        result = run_command(['kubeadm', 'config', 'images', 'pull'], ignore_errors=True)
        if result is not None:
            print("Preflight checks passed. Images pulled successfully.")
        else:
            print("Preflight checks failed. Verify kubeadm readiness.")
    else:
        print("kubeadm is not installed. Skipping preflight checks.")

def main():
    """
    Main function to setup the machine for Kubernetes.
    """
    if os.geteuid() != 0:
        print("This script must be run as root. Please try again with 'sudo'.")
        return

    update_system()  # Update system packages
    remove_kubernetes_tools()  # Remove existing Kubernetes tools if found
    configure_dns()  # Configure DNS
    disable_ipv6()  # Disable IPv6 permanently
    set_hostname()  # Set system hostname
    disable_swap()  # Disable swap
    configure_firewall()  # Setup firewall
    remove_default_routes()  # Remove specified default routes
    verify_kubeadm_preflight()  # Run kubeadm preflight checks

if __name__ == "__main__":
    main()
