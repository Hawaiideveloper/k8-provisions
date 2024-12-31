#!/bin/bash

# Exit immediately if a command fails
set -e



# Clean up any malformed installers

# Define the path to the file
FILE="/etc/apt/sources.list"

# Get current owner and group
ORIGINAL_OWNER=$(stat -c '%U' "$FILE")
ORIGINAL_GROUP=$(stat -c '%G' "$FILE")
ORIGINAL_PERMISSIONS=$(stat -c '%a' "$FILE")

# Save original owner, group, and permissions to a file
echo "$ORIGINAL_OWNER:$ORIGINAL_GROUP:$ORIGINAL_PERMISSIONS" > /tmp/original_perms.txt

# Take ownership of the file
sudo chown $USER:$USER "$FILE"

# Comment out the specific line in the file
sudo sed -i 's/^\(deb \[check-date=no\] file:\/\/\/cdrom.*\)/#\1/' "$FILE"

# Restore the original owner, group, and permissions
sudo chown "$ORIGINAL_OWNER":"$ORIGINAL_GROUP" "$FILE"
sudo chmod "$ORIGINAL_PERMISSIONS" "$FILE"

# Update package lists
sudo apt update









# Fix any DNS issues that could prevent kublet from working
# Define the target file
RESOLV_FILE="/etc/resolv.conf"

# Backup the existing resolv.conf file
if [ -f "$RESOLV_FILE" ]; then
    cp "$RESOLV_FILE" "${RESOLV_FILE}.backup"
    echo "Backup created at ${RESOLV_FILE}.backup"
fi

# Overwrite resolv.conf with new content
echo "fixing DNS so that kublet will run without issues"
cat <<EOF > "$RESOLV_FILE"
nameserver 172.100.55.2
nameserver 8.8.4.4
search albrightlabs.local
EOF

echo "Updated $RESOLV_FILE with new DNS configuration."
echo "now reloading the dns"
sudo systemctl restart systemd-resolved


# Disable swap (Kubernetes requires swap to be off)
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/\/swap.img/ s/^/#/' /etc/fstab
echo "sometimes this does not work and needs manual intervention, see below"
echo "if the line says this: /swap.img       none    swap    sw      0       0"
echo "then you need to go to /etc/fstab and comment it out"
grep '/swap.img' /etc/fstab


# Enable IP forwarding
# echo "Temporarily Enable IP Forwarding:"
# sudo sysctl -w net.ipv4.ip_forward=1

# echo "Persist IP Forwarding Across Reboots:"
# echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf

# echo "Reload the configuration:"
# sudo sysctl --system

# echo "Verify the setting .... it should equal 1"
# cat /proc/sys/net/ipv4/ip_forward
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Verify that net.ipv4.ip_forward is set to 1 with
sysctl net.ipv4.ip_forward

# Run the following command to uninstall all conflicting packages:
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done



# Setup Docker Apt-Repository for containerD
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update


# Now install only containerD
sudo apt-get install containerd.io

# Generate the default configuration for containerD
containerd config default | \
sed 's/SystemdCgroup = false/SystemdCgroup = true/' | \
sed 's/sandbox_image = "registry.k8s.io\/pause:3.6"/sandbox_image = "registry.k8s.io\/pause:3.10"/' | \
sudo tee /etc/containerd/config.toml

# Now restart containerD to ensure it is working
sudo systemctl restart containerd
sudo systemctl status containerd
sudo systemctl enable containerd


# # This script checks if /etc/crictl.yaml exists. If it doesn't, the script creates the file with the initial content.
# # If the file exists, it uses sed to insert the lines as you originally intended.

# if [ ! -f /etc/crictl.yaml ]; then
#     echo "File not found, creating..."
#     echo -e "runtime-endpoint: unix:///run/containerd/containerd.sock\nimage-endpoint: unix:///run/containerd/containerd.sock\ntimeout: 10\ndebug: false" | sudo tee /etc/crictl.yaml > /dev/null
# else
#     sudo sed -i '1i runtime-endpoint: unix:///run/containerd/containerd.sock\nimage-endpoint: unix:///run/containerd/containerd.sock\ntimeout: 10\ndebug: false' /etc/crictl.yaml
# fi


# Instructions are for Kubernetes v1.31
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Download the public signing key for the Kubernetes package
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
sudo mkdir -p -m 755 /etc/apt/keyrings

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg



# Update and install Kubernetes tools
echo "Updating and installing Kubernetes tools..."
sudo apt-get update
K8S_VERSION="1.31.4-1.1"  # most stable kubernetes version that works wirh calico 
sudo apt-get install -y kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# We need to restart all services
sleep 3
echo "you should say yes to restarting all services"


# Pre=pull required images
K8S_VER="1.31.4"
sudo kubeadm config images pull --kubernetes-version=$K8S_VERS


# # Initialize Kubernetes control plane
# echo "Initializing Kubernetes control plane..."
# POD_NETWORK_CIDR="192.168.79.0/24"
# K8S_VER="1.31.4"
# sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --kubernetes-version=$K8S_VER
# echo "if this fails you can try sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --kubernetes-version=$K8S_VERSION --ignore-preflight-errors=all"

# You can now join worker nodes using a command like this
# Then you can join any number of worker nodes by running the following on each as root:

# kubeadm join 172.100.55.20:6443 --token tkkiyb.76u6s7gwxqgm602h \
# 	--discovery-token-ca-cert-hash sha256:fcf0da56bf564a19b7e4bf02fda824c85b5d301cb7c21e0b90c3eca02214a448 


#################################### YOu need to Reboot cause nothing really will work on the next steps #################
# sudo reboot

# # Fixing the kube-system not seeing the needed files
# sudo kubeadm init phase kubelet-start


# # Install Calico
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# # Restart Kublet to allow Calico to be configured
# sudo systemctl restart kubelet


# Join the cluster
kubeadm join 172.100.55.20:6443 --token pdgak2.ugmiou5yk80y4xmn \
	--discovery-token-ca-cert-hash sha256:1fae35e1de806cda88758d375bbb6942857ad882e5149651632771abb3acdeeb 

 
# Set up kubeconfig for the current user
echo "Setting up kubeconfig..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
