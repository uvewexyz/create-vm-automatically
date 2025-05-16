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

5. Before using the `create_vm_auto.sh` script, copy the image first(avoiding to download the image again, as the VM will use its image)
```bash
cp /tmp/images/jammy-server-cloudimg-amd64.img /tmp/workdir && cp /tmp/images/focal-server-cloudimg-amd64.img /tmp/workdir &&  cp /tmp/images/almaLinux9-latest.x86_64.img /tmp/workdir && cp /tmp/images/centos-stream9-latest.img /tmp/workdir && cp /tmp/images/openwrt-24.10.1-x86-generic-ext4-combined.img /tmp/workdir
```

6. Edit the  `create_vm_auto.sh` script, pay attention in this variable section. Adjust the variable value with the path of the image copy

```bash
### Before ###
ubuntu22="/tmp/<image_dir>/<your_ubuntu22.img>"
ubuntu20="/tmp/<image_dir>/<your_ubuntu20.img>"
almalinux9="/tmp/<image_dir>/<your_almaLinux9.img>"
centosstream9="/tmp/<image_dir>/<your_centos-stream9.img>"
openwrt="/tmp/<image_dir>/<your_openwrt.img>"
```

```bash
### After ###
ubuntu22="/tmp/workdir/jammy-server-cloudimg-amd64.img"
ubuntu20="/tmp/workdir/focal-server-cloudimg-amd64.img"
almalinux9="/tmp/workdir/almaLinux9-latest.x86_64.img"
centosstream9="/tmp/workdir/centos-stream9-latest.img"
openwrt="/tmp/workdir/openwrt-24.10.1-x86-generic-ext4-combined.img"
```

7. Usage example
```bash
./create_vm_auto.sh
```
![image](https://github.com/user-attachments/assets/a52e4526-68ce-4719-9671-c4ef91a4e293)
![image](https://github.com/user-attachments/assets/f330e284-3ae6-4436-8bc0-fe4880c59bba)
