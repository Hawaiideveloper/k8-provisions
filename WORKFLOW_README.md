# Kubernetes Cluster Setup Workflow

This repository provides automated workflows for setting up a Kubernetes cluster using kubeadm with consistent IP addressing on the 172.100.10.x/24 network.

## Overview

The workflow consists of two main scripts:
- `master-workflow.sh` - Sets up the Kubernetes control plane (master node)
- `worker-workflow.sh` - Sets up worker nodes to join the cluster

## Network Configuration

### IP Address Scheme
- **Master Node**: 172.100.10.10
- **Worker Nodes**: 172.100.10.11, 172.100.10.12, 172.100.10.13, etc.
- **Gateway**: 172.100.10.1
- **Pod Network**: 192.168.79.0/24

### Hostname Scheme
- **Master**: k8-master
- **Workers**: k8-worker-01, k8-worker-02, k8-worker-03, etc.

## Prerequisites

### System Requirements
- Ubuntu 22.04 LTS
- Minimum 2 vCPU
- Minimum 2 GB RAM
- Network connectivity between nodes

### VM Setup
1. Create Ubuntu 22.04 VMs with the following specifications:
   - **Master Node**: 2 vCPU, 2 GB RAM
   - **Worker Nodes**: 2 vCPU, 2 GB RAM each

2. Ensure network interfaces are configured for the 172.100.10.x/24 subnet

## Quick Start

### Step 1: Master Node Setup

1. **Clone the repository** on the master node:
   ```bash
   git clone <repository-url>
   cd k8-provisions
   ```

2. **Make the script executable**:
   ```bash
   chmod +x master-workflow.sh
   ```

3. **Run the master workflow**:
   ```bash
   sudo ./master-workflow.sh
   ```

4. **Follow the prompts** - the script will:
   - Configure static IP (172.100.10.10)
   - Set hostname (k8-master)
   - Install and configure containerd
   - Install Kubernetes components
   - Initialize the control plane
   - Install Calico CNI
   - Generate join command for worker nodes

### Step 2: Worker Node Setup

For each worker node:

1. **Clone the repository** on the worker node:
   ```bash
   git clone <repository-url>
   cd k8-provisions
   ```

2. **Make the script executable**:
   ```bash
   chmod +x worker-workflow.sh
   ```

3. **Run the worker workflow**:
   ```bash
   sudo ./worker-workflow.sh
   ```

4. **Follow the prompts**:
   - Enter worker node number (1, 2, 3, etc.)
   - The script will configure IP (172.100.10.11, 172.100.10.12, etc.)
   - Enter the join command from the master node

### Step 3: Post-Setup Configuration

1. **Label worker nodes** (run on master):
   ```bash
   kubectl label nodes k8-worker-01 node-role.kubernetes.io/worker-node=worker --overwrite
   kubectl label nodes k8-worker-02 node-role.kubernetes.io/worker-node=worker --overwrite
   # Repeat for each worker node
   ```

2. **Verify cluster status**:
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

## Script Features

### Master Workflow (`master-workflow.sh`)
- ✅ Automatic cloud-init disabling
- ✅ Static IP configuration (172.100.10.10)
- ✅ Hostname setup (k8-master)
- ✅ DNS configuration for kubelet compatibility
- ✅ Swap disabling
- ✅ System parameter optimization
- ✅ Containerd installation and configuration
- ✅ Kubernetes components installation
- ✅ Control plane initialization
- ✅ Calico CNI installation
- ✅ Join command generation
- ✅ Node labeling

### Worker Workflow (`worker-workflow.sh`)
- ✅ Interactive worker node numbering
- ✅ Automatic IP assignment (172.100.10.11+)
- ✅ Hostname setup (k8-worker-0X)
- ✅ All system configurations from master
- ✅ Connectivity testing to master
- ✅ Cluster joining
- ✅ Status verification

## Network Troubleshooting

### Check Network Configuration
```bash
# Check IP configuration
ip addr show

# Check routing
ip route show

# Test connectivity
ping 172.100.10.10  # From worker to master
ping 172.100.10.11  # From master to worker
```

### Common Network Issues
1. **Interface name mismatch**: Edit the script to change `ens33` to your actual interface name
2. **Gateway unreachable**: Verify gateway IP (172.100.10.1) is correct
3. **DNS issues**: Check DNS server configuration

## Verification Commands

### Cluster Status
```bash
# Check node status
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Check cluster info
kubectl cluster-info
```

### Node Details
```bash
# Get detailed node information
kubectl describe node k8-master
kubectl describe node k8-worker-01
```

### Network Verification
```bash
# Check Calico pods
kubectl get pods -n kube-system | grep calico

# Check network policies
kubectl get networkpolicies --all-namespaces
```

## Troubleshooting

### Master Node Issues
1. **kubeadm init fails**: Check if swap is disabled and system parameters are set
2. **Calico pods not running**: Restart kubelet after Calico installation
3. **DNS issues**: Verify resolv.conf configuration

### Worker Node Issues
1. **Cannot join cluster**: Verify join command and network connectivity
2. **Node not showing up**: Check kubelet service status
3. **Pods not scheduling**: Verify node labels and taints

### Common Commands
```bash
# Check kubelet status
sudo systemctl status kubelet

# Check containerd status
sudo systemctl status containerd

# View kubelet logs
sudo journalctl -u kubelet -f

# Reset node (if needed)
sudo kubeadm reset
```

## Configuration Files

### Network Configuration
The scripts create `/etc/netplan/01-netcfg.yaml` with static IP configuration.

### DNS Configuration
The scripts configure `/etc/resolv.conf` for kubelet compatibility.

### System Parameters
The scripts set up `/etc/sysctl.d/k8s.conf` with required kernel parameters.

## Security Notes

- Scripts require sudo privileges
- Network configuration changes may temporarily disconnect SSH
- Backup existing configurations before running scripts
- Test in a lab environment before production use

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review logs: `sudo journalctl -u kubelet -f`
3. Verify network connectivity between nodes
4. Ensure all prerequisites are met

## Version Information

- **Kubernetes Version**: 1.31.4
- **Containerd Version**: Latest stable
- **Calico Version**: Latest stable
- **Ubuntu Version**: 22.04 LTS 