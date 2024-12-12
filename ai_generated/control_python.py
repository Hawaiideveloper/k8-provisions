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
        "Failed to update system."
    )
    run_command(
        "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
        "Failed to install prerequisites."
    )

# Function to add the CRI-O repository
def add_crio_repository():
    """
    Adds the CRI-O repository and imports the required GPG key.
    Ensures repositories are correctly linked with their signing key.
    """
    print("Adding CRI-O repository...")

    # Variables for repository setup
    os_version = "xUbuntu_22.04"
    cri_version = "1.28"
    gpg_key_url = "https://packages.cloud.google.com/apt/doc/apt-key.gpg"
    gpg_key_path = "/usr/share/keyrings/libcontainers-archive-keyring.gpg"

    try:
        # Step 1: Import the GPG key
        print("Importing GPG key for CRI-O repository...")
        run_command(
            f"curl -fsSL {gpg_key_url} | sudo gpg --dearmor -o {gpg_key_path}",
            "Failed to import GPG key for CRI-O repository."
        )

        # Step 2: Add the base repository
        print("Adding CRI-O base repository...")
        crio_repo = (
            f"deb [signed-by={gpg_key_path}] "
            f"https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/{os_version}/ /"
        )
        run_command(
            f"echo \"{crio_repo}\" | sudo tee /etc/apt/sources.list.d/libcontainers.list",
            "Failed to add base CRI-O repository."
        )

        # Step 3: Add the version-specific repository
        print("Adding CRI-O version-specific repository...")
        cri_version_repo = (
            f"deb [signed-by={gpg_key_path}] "
            f"https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/{cri_version}/{os_version}/ /"
        )
        run_command(
            f"echo \"{cri_version_repo}\" | sudo tee /etc/apt/sources.list.d/cri-o.list",
            "Failed to add version-specific CRI-O repository."
        )

        # Step 4: Update apt package list
        print("Updating package list...")
        run_command(
            "sudo apt-get update",
            "Failed to update package list after adding CRI-O repository."
        )
        
        print("CRI-O repository added successfully.")

    except Exception as e:
        print(f"Error adding CRI-O repository: {e}")
        raise




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

# Function to initialize the Kubernetes control plane
def initialize_control_plane():
    print("Initializing the Kubernetes control plane...")
    run_command(
        "sudo kubeadm init --pod-network-cidr=192.168.0.0/16",
        "Failed to initialize Kubernetes control plane."
    )

# Function to configure kubectl for admin user
def configure_kubectl():
    print("Configuring kubectl for the admin user...")
    run_command("mkdir -p $HOME/.kube", "Failed to create .kube directory.")
    run_command(
        "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
        "Failed to copy admin.conf to .kube directory."
    )
    run_command(
        "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
        "Failed to change ownership of .kube/config."
    )

# Function to install Calico network plugin
def install_calico():
    print("Installing Calico network plugin...")
    run_command(
        "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml",
        "Failed to install Calico network plugin."
    )

if __name__ == "__main__":
    try:
        update_system()
        add_crio_repository()
        install_crio()
        add_kubernetes_repository()
        install_kubernetes_components()
        disable_swap()
        initialize_control_plane()
        configure_kubectl()
        install_calico()
        print("Control plane setup complete!")
    except Exception as e:
        print(f"Setup failed: {e}")
