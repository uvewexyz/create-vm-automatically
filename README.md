# create_vm_auto.sh
To create a VM automatically, you can use this script to do so. I used this script in a QEMU/KVM environment.

# Prerequisites
Make sure your PC/server/laptop/etc. already has the packages below:
1. cpu-checker
2. qemu-system
3. qemu-kvm
4. libvirt-daemon-system
5. virtinst

> ### Notes:
> Verify once more that your device is already set up with Qemu/KVM. This URL can be read and followed if it is not configured:
> - https://linuxize.com/post/how-to-install-kvm-on-ubuntu-20-04
> - https://www.freecodecamp.org/news/turn-ubuntu-2404-into-a-kvm-hypervisor

# Usage Example
> ### FYI:
> I run this script with **root** user

1. Firstly, download the `create_vm_auto.sh` script
```bash
git clone https://github.com/uvewexyz/create-vm-automatically.git
```
```bash
cd create-vm-automatically
```

2. Give execute permission to the `create_vm_auto.sh` script
```bash
chmod +x create_vm_auto.sh && ls -l
```

3. Prepare the distro cloud image, follow this step to installing
```bash
mkdir /tmp/images
```
```bash
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img -O /tmp/images/focal-server-cloudimg-amd64.img
```
```bash
wget https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2 -O /tmp/images/almaLinux9-latest.x86_64.img
```
```bash
wget https://downloads.openwrt.org/releases/24.10.1/targets/x86/generic/openwrt-24.10.1-x86-generic-generic-ext4-combined.img.gz -O /tmp/images/openwrt-24.10.1-x86-generic-ext4-combined.img.gz

gunzip /tmp/images/openwrt-24.10.1-x86-generic-ext4-combined.img.gz
```
```bash
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -O /tmp/images/jammy-server-cloudimg-amd64.img
```
```bash
wget https://cloud.centos.org/altarch/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2 -O /tmp/images/centos-stream9-latest.img  
```

4. After downloading the distro cloud image, to make it easier to mention the script directory, change the name to `workdir`
```bash
cd .. && mv create-vm-automatically workdir
```
```bash
cd workdir
```

5. Usage example
```bash
./create_vm_auto.sh
```

6. Pict
![image](https://github.com/user-attachments/assets/221769b9-c7cc-4f0e-ad8b-a508a73b5b7c)
![image](https://github.com/user-attachments/assets/75f98b04-1d98-4c72-b70a-fac85ca5ea38)

7. After running the script you will get new image from the VM installation
```bash
ls -l /tmp/workdir/

### Output ###
...
-rw-r--r-- 1 libvirt-qemu kvm 126353408 May 17 14:19 /tmp/workdir/openwrt-17_05_25_14_18_47.img
...
```
