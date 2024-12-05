I am deciding to move to a branch called ansible_way


Originally wrote for Ubuntu 16.04 LTS:
The kubernetes-xenial repository is designed for Ubuntu 16.04 LTS, which is also known by the codename Xenial Xerus.



If you want to do this and not spend hours manually repeating yourself come to that branch

### Test communication to each device using:

```ansible --key-file ~/.ssh/kube_rsa -i inventory all -m ping```



### Run your playbook on all nodes


```ansible-playbook --key-file ~/.ssh/kube_rsa -i inventory  ansible/k8s-install.yml```


### Run this on the master
```ansible-playbook --key-file ~/.ssh/kube_rsa -i inventory  ansible/master.yml```



### Run this on the worker nodes:

```ansible-playbook --key-file ~/.ssh/kube_rsa -i inventory  playbooks/k8s/workers.yml```


### Summary:
Once the playbook is executed successfully log into the master node and run kubectl get nodes which should display the following output. If some of your node show not ready give it a couple of minutes to get ready.


If you are lazy and want this to work quickly while you make dinner, simply use the bootstrap

```bash
ansible-playbook --key-file ~/.ssh/kube_rsa -i inventory  playbooks/k8s/bootstrap.yml```