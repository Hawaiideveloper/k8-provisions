# KUBEADM (Kubernetes) Install and configurations


### Requirements:  

Minimum 2 Ubuntu 22.04 Virtual Machines (Preferably 3)  

    - Master Node:  

        - 2 vCPU  

        - 2 GB RAM  

    - Worker Node(s):  

        - 2 vCPU  

        - 2 GB RAM  

    Networking Requirements:  

        - Server Network (172.x.x.x)  

        - Pod Network  (192.x.x.x)          
        


Reference taken kubeadm version 1.31 within Kubernetes Documentation

## Note after joining a worker node please be sure to run on the control plane

```bash
kubectl label nodes <k8-worker-node-01 or your workers name> node-role.kubernetes.io/worker-node=worker --overwrite
```
Make sure to substitue your workers name with the actual hostname

