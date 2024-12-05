I am deciding to move to a branch called ansible_way


Originally wrote for Ubuntu 16.04 LTS:
The kubernetes-xenial repository is designed for Ubuntu 16.04 LTS, which is also known by the codename Xenial Xerus.

This repo is designed to work for multiple Ubuntu versions, despite its name (xenial). It is valid for:
Ubuntu 16.04 (Xenial)
Ubuntu 18.04 (Bionic)
Ubuntu 20.04 (Focal)
Ubuntu 22.04 (Jammy)
The key is that the kubernetes-xenial repository supports multiple Ubuntu LTS versions.

If you want to do this and not spend hours manually repeating yourself come to that branch

### Test communication to each device using:

```bash 
ansible --key-file ~/.ssh/kube_rsa -i inventory all -m ping```



### Run your playbook on all nodes


```ansible-playbook --key-file ~/.ssh/kube_rsa -i inventory  ansible/k8s-install.yml```  



### Run this on the master
```ansible-playbook --key-file ~/.ssh/kube_rsa -i inventory  ansible/master.yml```  




### Run this on the worker nodes:
  

```bash 
ansible-playbook --key-file ~/.ssh/kube_rsa -i inventory  ansible/workers.yml```


```bash
ansible-playbook --key-file ~/.ssh/kube_rsa -i inventory  ansible/bootstrap.yml```



### Placeholder

If you decide to use a `vars.yml` file, you’ll need to modify the playbook to reference variables from that file, replacing hardcoded values where necessary. This makes your playbook cleaner and more reusable.




### Step-by-Step Changes

1. **Create the `vars.yml` File**
   Define the variables in a `vars.yml` file. For example:

   ```yaml
   # vars.yml

   kubelet_version: "1.20.1-00"
   kubeadm_version: "1.20.1-00"
   kubectl_version: "1.20.1-00"

   containerd_conf_path: "/etc/containerd/config.toml"
   modules_conf_path: "/etc/modules-load.d/containerd.conf"
   sysctl_conf_path: "/etc/sysctl.d/99-kubernetes-cri.conf"
   kubernetes_repo_path: "/etc/apt/sources.list.d/kubernetes.list"

   pod_network_cidr: "192.168.0.0/16"
   service_cidr: "10.96.0.0/12"
   ```

2. **Reference `vars.yml` in the Playbook**
   Ensure the `vars_files` section in the playbook points to the correct path of the `vars.yml` file:

   ```yaml
   vars_files:
     - ../../vars.yml
   ```

   Adjust the path as needed depending on where `vars.yml` is relative to your playbook.

3. **Replace Hardcoded Values with Variables**
   Update the playbook to use variables instead of hardcoded values. For example:

   ```yaml
   - hosts: k8s-master, k8s-workers
     become: yes
     become_user: root
     become_method: sudo
     gather_facts: yes
     vars_files:
       - ../../vars.yml
     tasks:
       - name: Create containerd config file
         ansible.builtin.file:
           path: "{{ modules_conf_path }}"
           state: "touch"

       - name: Add config for containerd
         blockinfile:
           path: "{{ modules_conf_path }}"
           block: |
                 overlay
                 br_netfilter

       - name: modprobe
         shell: |
                 sudo modprobe overlay
                 sudo modprobe br_netfilter

       - name: Set system configs for Kubernetes networking
         file:
           path: "{{ sysctl_conf_path }}"
           state: "touch"

       - name: Add config for containerd
         blockinfile:
           path: "{{ sysctl_conf_path }}"
           block: |
                 net.bridge.bridge-nf-call-iptables = 1
                 net.ipv4.ip_forward = 1
                 net.bridge.bridge-nf-call-ip6tables = 1

       - name: Apply new settings
         command: sudo sysctl --system

       - name: Install containerd
         shell: |
                 sudo apt-get update && sudo apt-get install -y containerd
                 sudo mkdir -p /etc/containerd
                 sudo containerd config default | sudo tee {{ containerd_conf_path }}
                 sudo systemctl restart containerd

       - name: Disable swap
         shell: |
                 sudo swapoff -a
                 sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

       - name: Install and config dependencies
         shell: |
                 sudo apt-get update && sudo apt-get install -y apt-transport-https curl
                 curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

       - name: Create kubernetes repo file
         file:
           path: "{{ kubernetes_repo_path }}"
           state: "touch"

       - name: Add K8s source
         blockinfile:
           path: "{{ kubernetes_repo_path }}"
           block: |
                 deb https://apt.kubernetes.io/ kubernetes-xenial main

       - name: Install kubernetes
         shell: |
                 sudo apt-get update
                 sudo apt-get install -y kubelet={{ kubelet_version }} kubeadm={{ kubeadm_version }} kubectl={{ kubectl_version }}
                 sudo apt-mark hold kubelet kubeadm kubectl
   ```

4. **Validate Changes**
   After making the changes, validate the playbook:
   - Run it with the `--check` flag to simulate execution:
     ```bash
     ansible-playbook playbook.yml --check
     ```
   - Confirm that variables are correctly substituted.

5. **Run the Playbook**
   Once validated, execute the playbook:
   ```bash
   ansible-playbook playbook.yml
   ```

### Benefits of Using Variables
- **Reusability**: You can reuse the playbook for different setups by simply modifying the `vars.yml` file.
- **Maintainability**: It’s easier to manage configurations without hunting for hardcoded values in the playbook.
- **Scalability**: Supports multiple environments (e.g., dev, test, prod) with different configurations using separate `vars.yml` files.