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
line="-------------------------------------------------------------------------------------"

# Declare arrays to keep the virtual network names and interfaces
declare -a net_name
declare -a net_if

# Start of the script
echo "$line"
read -n 2 -e -i "Y" -p "Welcome, Do you want to create a VM? (Y/n, default Y): " response;
echo "$line"
sleep 1;

if [[ "$response" != "Y" && "$response" != "y" ]]; then
  echo "Goodbye...";
  exit 1;
fi

# Validate if the VM name already exists
valid_name() {
  # Prompt to specify th VM name
  read -e -i "vm$(date +%d_%m_%y)" -p "Create the VM name: " vm_name;
  echo "$line"

  if virsh list --all --name | grep -qwF -- "$vm_name"; then
    echo "This name is already use, exit script...";
    sleep 3;
    clear && valid_name;
  else
    echo -e "Keep vm name: $red $vm_name $reset";
    echo "$line"
  fi
}

valid_name;

# Validate the VM memory size
valid_mem() {
  # Prompt to specify thre VM memory size
  vm_mem_max="$(grep -i "MemAvailable" /proc/meminfo | awk '{print $2/1048}' | cut -d. -f1)"
  echo -e "Minimal input: $red 128 $reset MiB";
  echo -e "Maximal input: $red $vm_mem_max $reset MiB";
  read -e -p "Specify size memory to allocate for the VM, in MiB: " vm_mem;
  echo "$line"

  if [[ "$vm_mem" -lt 128 || "$vm_mem" -ge "$vm_mem_max" ]]; then
    echo "Invalid memory size! Enter value between $red 128 $reset MiB - $red $vm_mem_max $reset MiB";
    echo "$line";
    sleep 3;
    clear && valid_mem;
  else
    echo -e "Keep vm memory size: $red $vm_mem $reset MiB";
    echo "$line";
  fi
}

valid_mem;

# Validate allocating the VM vCPU
valid_vcpu() {
  # Prompt to specify the VM vCPU size
  echo -e "Minimal input: $red 1 $reset vCPU";
  echo -e "Maximal input: $red $(nproc) $reset vCPU";
  read -e -i "1" -p "Size of virtual cpus for the VM: " vm_vcpu;
  echo "$line"

  if [[ "$vm_vcpu" -lt 1  || "$vm_vcpu" -ge "$(nproc)" ]]; then
    echo "Invalid vCPU size! Enter value between $red 1 $reset vCPU - $red $(nproc) $reset vCPU";
    echo "$line";
    sleep 3;
    clear && valid_vcpu;
  else
    echo -e "Keep vm vCPU size: $red $vm_vcpu $reset vCPU";
    echo "$line";
  fi
}

valid_vcpu;

# Validate the OS VM
valid_os() {
  # Prompt to select the OS for the VM
  echo -e "
  1.) ubuntu22.04
  2.) ubuntu20.04
  3.) almalinux9
  4.) centos-stream9
  5.) openwrt
  "

  echo "Example selection: 1, 2, 3, 4, or 5";
  read -e -p "Type OS number for your VM OS: " vm_os;
  echo "$line"
}

valid_os;

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
echo "$line"

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
    sleep 3;
    clear && valid_os;
    ;;
esac
# esac

# Prompt to specify the size of the secondary disk
read -e -i "5" -p "Specify size for a new secondary disk image in Gigabyte: " vm_disk2_size;
echo "$line"

# Validate attached virtual network to the VM 
valid_vir_net() {
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
  echo "Example selection: 1, 2, 3, or etc";
  read -e -p "Select the number of the virtual network to attach to the VM: " net_num;
  echo "$line"
  sleep 1;

  # Validate the selected virtual network number
  if [[ "$net_num" =~ ^[0-9]+$ && "$net_num" -gt 0 && "$net_num" -le "${#net_name[@]}" ]]; then
    vm_net_select="${net_name[$((net_num - 1))]}";
    vm_if_select="${net_if[$net_num - 1]}";
    ip_gw="$(ip addr show $vm_if_select | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.1\/24/g')";
    ip_start="$(ip addr show $vm_if_select | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.2\/24/g')";
    ip_end="$(ip addr show $vm_if_select | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.254\/24/g')";
    echo -e "Selecting Virtual Network: $red $vm_net_select $reset | Interface: $red $vm_if_select $reset";
    echo "$line"
    sleep 3;
    echo -e "Your gateway: $red $ip_gw $reset";
    echo -e "Your ip address start: $red $ip_start $reset";
    echo -e "Your ip address end: $red $ip_end $reset";
    echo -e "Example IP address: $red $(ip addr show $vm_if_select | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.10\/24/g') $reset";
    echo "$line"
  else
    echo "Invalid selection. Please select a valid number from the list.";
    sleep 3;
    clear && valid_vir_net;
  fi
}

valid_vir_net;

# Validate the IP address
valid_ip() {
  ip_addr="${ip_gw%%/*}"
  ip_net="$(ipcalc -n "$ip_gw" | awk -F: '/Network/ {gsub(/ /, "", $2); print $2}' | cut -d/ -f1)"
  netmask="$(ipcalc "$ip_gw" | awk -F: '/Netmask/ {gsub(/ /, "", $2); print $2}' | cut -d= -f1)"

  # Prompt to assign a ip
  read -e -p "Assign the ip address to the VM: " ip_num;
  echo "$line"

  ip_input=$(ipcalc -n "$ip_num" "$netmask" | awk -F: '/Network/ {gsub(/ /, "", $2); print $2}' | cut -d/ -f1)

  if [[ "$ip_input" != "$ip_net" ]]; then
    echo "IP $ip_num not in subnet $ip_net! Please enter again";
    sleep 3;
    clear && valid_ip;
  else
    echo -e "Keep ip address: $red $ip_num $reset";
    echo "$line"
  fi
}

valid_ip;

# Prompt to create a new user for the VM
read -e -i "john" -p "Create a new user for the VM: " vm_user;
echo "$line";

# Prompt to create a password for new user
read -e -p "Create a password for the user: " vm_passwd;
secret="$(echo "$vm_passwd" | mkpasswd -s --method=SHA-512 --rounds=500000)"
echo "$line";

# Prompt to add public key SSH
read -e -i "$(cat ~/.ssh/id_ed25519.pub)" -p "Add your pub key to the VM: " vm_pubkey;
echo "$line";

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

# Update, upgrade, and install packages
package_upgrade: true
package_update: true
packages:
- neofetch
- vim
- nginx

runcmd:
  - netplan apply
  - echo "AllowUsers $vm_user" >> /etc/ssh/sshd_config
  - sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
  - systemctl restart sshd
  - chmod 600 /etc/netplan/99-custom-network.yaml
  - systemctl enable nginx && systemctl start nginx
  - cloud-init status --wait
EOF

# Process the VM creation
echo -e "Create VM name $red $vm_name $reset";
echo "$line"
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
  echo "$line"
  virsh list --all | grep -i "$vm_name";
else
  echo "VM failed to create! There was an error during the process.";
  sleep 1;
  echo -e "You can check the $red journalctl -u libvirtd -xe $reset for more details.";
  exit 1;
fi