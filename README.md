Experimental:

we left off on this chat:





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


Reference taken from the sources below and an AI called ChatGPT

- https://github.com/techiescamp/kubeadm-scripts
- https://www.youtube.com/watch?v=xX52dc3u2HU
