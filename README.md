Experimental:

we left off on this chat: was calico





# KUBEADM (Kubernetes) Install and configurations


### Requirements:  

Minimum 2 Ubuntu Virtual Machines (Preferably 3)  

    - Master Node:  

        - 2 vCPU  

        - 2 GB RAM  

    - Worker Node(s):  

        - 1 vCPU  

        - 2 GB RAM  

    Networking Requirements:  

        - Server Network must be (10.x.x.x) or (172.x.x.x)  

        - Pod Network must be (192.x.x.x)          
        







If you want to do things manually please select manual folder


If you want an automated approach please use ansible





#### Issue found on local machines
---
* Note to remove multiple entries from your local host for ssh systems because you get error
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!

type this:
```bash
ssh-keygen -R k8-controlplane
```

Reference taken from 1.31 kubeadm within Kubernetes Docs, and ubuntu 22.04.  

## Note after joining a worker node please be sure to run on the control plane

```bash
kubectl label nodes <k8-worker-node-01 or your workers name> node-role.kubernetes.io/worker-node=worker --overwrite
```
Make sure to substitue your workers name with the actual hostname

