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
red="\033[0;31m"
reset="\033[0m"

# Declare arrays to keep the virtual network names and interfaces
declare -a net_name
declare -a net_if

# Start of the script
echo "-------------------------------------------------------------------------------------"
read -n 2 -e -i "Y" -p "Welcome, Do you want to create a VM? (Y/n, default Y): " response;
echo "-------------------------------------------------------------------------------------"
sleep 1;

if [[ "$response" != "Y" && "$response" != "y" ]]; then
  echo "Goodbye...";
  exit 1;
fi

# Prompt to specify th VM name
read -e -i "my-vm$(date +%d_%m_%y)" -p "Create the VM name: " vm_name;
echo "-------------------------------------------------------------------------------------"

# Validate if the VM name already exists
if virsh list --all --name | grep -qwF -- "$vm_name"; then
  echo "This name is already use, exit script...";
  echo "-------------------------------------------------------------------------------------"
  exit 1;
fi

# Prompt to specify thre VM memory size
read -e -i "512" -p "Size memory to allocate for the VM, in MiB: " vm_mem;
echo "-------------------------------------------------------------------------------------"

# Prompt to specify the VM vCPU size
read -e -i "1" -p "Size of virtual cpus for the VM: " vm_vcpu;
echo "-------------------------------------------------------------------------------------"

# Prompt to select the OS for the VM
echo -e "
1.) ubuntu22.04
2.) ubuntu20.04
3.) almalinux9
4.) centos-stream9
5.) openwrt
"
read -e -n 2 -p "Type OS number for your VM OS: " vm_os;
echo "-------------------------------------------------------------------------------------"

# Prompt to specify the size of the primary disk
read -e -i "15" -p "Specify size for the primary disk image in Gigabyte: " vm_disk1_size;

# Function to create, specify size, and formatting new disk images
copy_image() {
  src_img=$1
  dst_img=$2
  dst_path="$dst_dir/$dst_img"
  qemu-img create -q -b "$src_dir/$src_img" -f qcow2 -F qcow2 "$dst_path" "$vm_disk1_size"G
  echo "$dst_path"
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

# Show the primary disk image path
echo "Primary disk image path: $vm_disk1";
echo "-------------------------------------------------------------------------------------"

case "$vm_os" in
  1)
    vm_os="ubuntu22.04"
    ;;
  2)
    vm_os="ubuntu20.04"
    ;;
  3)
    vm_os="almalinux9"
    ;;
  4)
    vm_os="centos-stream9"
    ;;
  5)
    vm_os="unknown"
    ;;
  *)
    echo "Option not found!. Please select 1, 2, 3, 4, or 5!!!"
    exit 1
    ;;
esac

# Prompt to specify the size of the secondary disk
read -e -i "5" -p "Specify size for a new secondary disk image in Gigabyte: " vm_disk2_size;
echo "-------------------------------------------------------------------------------------"

# Populate the arrays with values from the net var and the iface var
for net in $(virsh net-list --all --name); do
  iface=$(virsh net-dumpxml $net | awk -F"'" '/bridge name=/{print $2}');
  net_name+=("$net")
  net_if+=("$iface")
done

# Check if user haven't any virtual networks
if [[ ${#net_name[@]} -eq 0 ]]; then
  echo "No virtual networks found. Please create a virtual network first.";
  echo "Exiting script...";
  sleep 1;
  exit 1;
fi

# List available virtual networks
echo "Available virtual networks:";
sleep 1;
for i in "${!net_name[@]}"; do
  num=$((i + 1));
  echo -e "$num.) Virtual Network: $red ${net_name[$i]} $reset | Interface: $red ${net_if[$i]} $reset";
done

# Prompt to select a virtual network
read -e -n 2 -p "Select the number of the virtual network to attach to the VM: " net_num;
echo "-------------------------------------------------------------------------------------"
sleep 1;

# Validate the selected virtual network number
if [[ "$net_num" =~ ^[0-9]+$ && "$net_num" -gt 0 && "$net_num" -le "${#net_name[@]}" ]]; then
  vm_net_select="${net_name[$((net_num - 1))]}";
  vm_if_select="${net_if[$net_num - 1]}";
  ip_gw="$(ip addr show $vm_if_select | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.1\/24/g')";
  echo -e "Selecting Virtual Network: $red $vm_net_select $reset | Interface: $red $vm_if_select $reset";
  echo "-------------------------------------------------------------------------------------"
  sleep 3;
  echo -e "Your gateway: $red $ip_gw $reset";
  echo -e "Your ip address start with: $red $(ip addr show $vm_if_select | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.2\/24/g') $reset";
  echo -e "Your ip address start with: $red $(ip addr show $vm_if_select | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.254\/24/g') $reset";
  echo -e "Example IP address: $red $(ip addr show $vm_if_select | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.10\/24/g') $reset";
  echo "-------------------------------------------------------------------------------------"
else
  echo "Invalid selection. Please select a valid number from the list.";
  exit 1;
fi

# Prompt to assign a ip
read -e -p "Assign the ip address to the VM: " ip_num;
echo "-------------------------------------------------------------------------------------"

# Prompt to create a new user for the VM
read -e -i "john" -p "Create a new user for the VM: " vm_user;
echo "-------------------------------------------------------------------------------------";

# Prompt to create a password for new user
read -e -p "Create a password for the user: " vm_passwd;
secret="$(echo "$vm_passwd" | mkpasswd -s --method=SHA-512 --rounds=500000)"
echo "-------------------------------------------------------------------------------------";

# Prompt to add public key SSH
read -e -i "$(cat ./key/id_ed25519.pub)" -p "Add your pub key to the VM: " vm_pubkey;
echo "-------------------------------------------------------------------------------------";

# Load config to user-data file
cat << EOF > "$dst_dir"/"$vm_name"-user-data
#cloud-config

# Set hostname
hostname: $vm_name

# Configure users, groups, password
users:
  - name: $vm_user
    hashed_passwd: $secret
    shell: /bin/bash
    lock_passwd: false
    groups: sudo
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - $vm_pubkey

# Load netowrk configuration
write_files:
  - path: /etc/netplan/99-custom-network.yaml
    content: |
      network:
        version: 2
        renderer: networkd
        ethernets:
          enp1s0:
            dhcp4: false
            addresses:
              - $ip_num
            nameservers:
              addresses: [ "8.8.8.8", "1.1.1.1" ]
            routes:
              - to: default
                via: $ip_gw

runcmd:
  - netplan apply
  - echo "AllowUsers $vm_user" >> /etc/ssh/sshd_config
  - sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
  - systemctl restart sshd
  - cloud-init status --wait

# Update, upgrade, and install packages
package_upgrade: true
package_update: true
packages:
- neofetch
- vim
EOF

# Process the VM creation
echo -e "Create VM name $red $vm_name $reset";
echo "-------------------------------------------------------------------------------------"
sleep 2;
virt-install -q -n "$vm_name" \
  --memory "$vm_mem" \
  --vcpus "$vm_vcpu" \
  --import \
  --disk path="$vm_disk1",format=qcow2 \
  --disk size="$vm_disk2_size" \
  --cloud-init user-data="$dst_dir"/"$vm_name"-user-data \
  --osinfo detect=on,name="$vm_os" \
  --network bridge="$vm_if_select" \
  --noautoconsole;

sleep 2;
echo "Result: ";

# Validate if the VM is already created
if virsh list --all --name | grep -qwF -- "$vm_name"; then
  echo -e "Successfully created VM with name $red $vm_name $reset";
  echo "-------------------------------------------------------------------------------------"
  virsh list --all | grep -i "$vm_name";
else
  echo "VM failed to create! There was an error during the process.";
  sleep 1;
  echo -e "You can check the $red journalctl -u libvirtd -xe $reset for more details.";
  exit 1;
fi