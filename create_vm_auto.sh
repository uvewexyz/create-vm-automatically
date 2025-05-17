#!/bin/bash

# Variables section
src_dir="/tmp/images"
dst_dir="/tmp/workdir"
timestamp=$(date +%d_%m_%y_%H_%M_%S)
ubuntu22="jammy-server-cloudimg-amd64.img"
ubuntu20="focal-server-cloudimg-amd64.img"
almalinux9="almaLinux9-latest.x86_64.img"
centosstream9="centos-stream9-latest.img"
openwrt="openwrt-24.10.1-x86-generic-ext4-combined.img"

# Specify the specs for the VM
echo "-------------------------------------------------------------------------------------"
read -n 1 -e -i "Y" -p "Welcome, this is the script to create a VM. Want to continue? (Y/n, default yes) : " response;
echo "-------------------------------------------------------------------------------------"
sleep 1;

if [[ "$response" != "Y" && "$response" != "y" ]]; then

  echo "Goodbye...";
  exit 1;

fi

read -e -i "my-vm$(date +%d_%m_%y)" -p "Create the VM name: " vm_name;
echo "-------------------------------------------------------------------------------------"

read -e -i "512" -p "Size memory to allocate for the VM, in MiB: " vm_mem;
echo "-------------------------------------------------------------------------------------"

read -e -i "1" -p "Size of virtual cpus for the VM: " vm_vcpu;
echo "-------------------------------------------------------------------------------------"

echo -e "
1.) ubuntu22
2.) ubuntu20
3.) almalinux9
4.) centosstream9
5.) openwrt
\n"
read -e -n 1 -i "5" -p "Select number of the menu to your VM OS: " vm_os;
echo "-------------------------------------------------------------------------------------"

read -e -i "5" -p "Allocacte new secondary disk image in Gigabyte to the VM: " vm_disk2;
echo "-------------------------------------------------------------------------------------"

sleep 1;

if virsh list --all --name | grep -qwF -- "$vm_name"; then

  echo "This name is already use, exit script...";
  echo "-------------------------------------------------------------------------------------"
  exit 1;

fi

copy_image() {
  src_img=$1
  dst_img=$2
  cp "$src_dir/$src_img" "$dst_dir/$dst_img"
  echo "$dst_dir/$dst_img"
}

case "$vm_os" in
  1)
    vm_disk1=$(copy_image "$ubuntu22" "ubuntu22-$timestamp.img")
    ;;
  2)
    vm_disk1=$(copy_image "$ubuntu20" "ubuntu20-$timestamp.img")
    ;;
  3)
    vm_disk1=$(copy_image "$almalinux9" "almalinux9-$timestamp.img")
    ;;
  4)
    vm_disk1=$(copy_image "$centosstream9" "centosstream9-$timestamp.img")
    ;;
  5)
    vm_disk1=$(copy_image "$openwrt" "openwrt-$timestamp.img")
    ;;
  *)
    echo "Option not found!. Please select 1, 2, 3, 4, or 5!!!"
    exit 1
    ;;
esac

# Process the VM creation
echo "Create VM name '$vm_name' ";
echo "-------------------------------------------------------------------------------------"
sleep 2;
virt-install -n "$vm_name" \
  --memory "$vm_mem" \
  --vcpus "$vm_vcpu" \
  --import \
  --disk "$vm_disk1" \
  --disk size="$vm_disk2" \
  --os-variant detect=on \
  --network bridge=$(virsh net-list --all | awk '{print $1}' | sed -n '3p') \
  --noautoconsole;

echo "Result: ";
sleep 2;
virsh list --all;
echo "-------------------------------------------------------------------------------------"
echo "VM '$vm_name' created successfully!";
echo "-------------------------------------------------------------------------------------"