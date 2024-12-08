Kubernetes control-plane requires static IPs 

the script convert_to_static_multi.py will make staic IPs from the DHCP allocation meaning

after the machine gets a DHCP IP, it is not ready for the script to turn that into a static IP


to supress the error/warnings 


** (process:2099): WARNING **: 09:26:33.632: Permissions for /etc/netplan/00-installer-config.yaml are too open. Netplan configuration should NOT be accessible by others.

** (process:2099): WARNING **: 09:26:33.632: Permissions for /etc/netplan/01-netcfg.yaml are too open. Netplan configuration should NOT be accessible by others.

** (process:2099): WARNING **: 09:26:33.632: gateway4 has been deprecated, use default routes instead.
See the 'Default routes' section of the documentation for more details.

** (process:2099): WARNING **: 09:26:33.632: gateway4 has been deprecated, use default routes instead.
See the 'Default routes' section of the documentation for more details.

** (process:2099): WARNING **: 09:26:33.632: gateway4 has been deprecated, use default routes instead.
See the 'Default routes' section of the documentation for more details.

** (process:2099): WARNING **: 09:26:33.632: Problem encountered while validating default route consistency.Please set up multiple routing tables and use routing-policy instead.
Error: Conflicting default route declarations for IPv4 (table: main, metric: default), first declared in ens35 but also in ens34
Netplan configuration applied successfully.




just do:



```bash
sudo chmod 600 /etc/netplan/00-installer-config.yaml
sudo chmod 600 /etc/netplan/01-netcfg.yaml
```
