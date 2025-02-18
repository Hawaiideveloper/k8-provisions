import subprocess

def run_command(command, error_message):
    try:
        subprocess.run(command, check=True, shell=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"Error: {error_message}\n{e}")
        raise

# Function to update the system and install prerequisites
def update_system():
    print("Updating system and installing prerequisites...")
    run_command(
        "sudo apt-get update",
        "Failed to update the system."
    )
    run_command(
        "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
        "Failed to install prerequisites."
    )

# Function to add the CRI-O repository
def add_crio_repository():
    print("Adding CRI-O repository...")
    os_version = "xUbuntu_22.04"
    cri_version = "1.28"
    crio_repo = (
        f"deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] "
        f"https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/{os_version}/ /"
    )
    cri_version_repo = (
        f"deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] "
        f"https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/{cri_version}/{os_version}/ /"
    )
    run_command(
        f"echo \"{crio_repo}\" | sudo tee /etc/apt/sources.list.d/libcontainers.list",
        "Failed to add CRI-O repository."
    )
    run_command(
        f"echo \"{cri_version_repo}\" | sudo tee /etc/apt/sources.list.d/cri-o.list",
        "Failed to add CRI-O version-specific repository."
    )

# Function to install CRI-O
def install_crio():
    print("Installing CRI-O...")
    run_command("sudo apt-get update", "Failed to update system after adding CRI-O repository.")
    run_command("sudo apt-get install -y cri-o cri-o-runc", "Failed to install CRI-O.")
    run_command("sudo systemctl enable crio", "Failed to enable CRI-O service.")
    run_command("sudo systemctl start crio", "Failed to start CRI-O service.")

# Function to add the Kubernetes repository
def add_kubernetes_repository():
    print("Adding Kubernetes repository...")
    run_command(
        "curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
        "Failed to add Kubernetes repository key."
    )
    run_command(
        "echo \"deb https://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee /etc/apt/sources.list.d/kubernetes.list",
        "Failed to add Kubernetes repository."
    )

# Function to install Kubernetes components
def install_kubernetes_components():
    print("Installing kubeadm, kubectl, and kubelet...")
    run_command("sudo apt-get update", "Failed to update system after adding Kubernetes repository.")
    run_command(
        "sudo apt-get install -y kubeadm kubectl kubelet",
        "Failed to install Kubernetes components."
    )
    run_command(
        "sudo apt-mark hold kubeadm kubectl kubelet",
        "Failed to mark Kubernetes components as held."
    )

# Function to disable swap
def disable_swap():
    print("Disabling swap...")
    run_command("sudo swapoff -a", "Failed to disable swap.")
    run_command(
        "sudo sed -i '/ swap / s/^/#/' /etc/fstab",
        "Failed to modify fstab to disable swap permanently."
    )

if __name__ == "__main__":
    try:
        update_system()
        add_crio_repository()
        install_crio()
        add_kubernetes_repository()
        install_kubernetes_components()
        disable_swap()
        print("Worker node setup complete!\nTo join the cluster, run the kubeadm join command provided during control plane initialization.")
    except Exception as e:
        print(f"Setup failed: {e}")
