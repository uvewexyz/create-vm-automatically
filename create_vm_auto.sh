#!/bin/bash

# Define several variables
blue="\033[1;34m"
green="\033[1;32m"
red="\033[1;31m"
yellow="\033[1;33m"
reset="\033[0m"
line="-------------------------------------------------------------------------------------"
src_dir="/var/lib/libvirt/images"
dst_dir="/var/lib/libvirt/workdir"
timestamp=$(date +%d_%m_%y_%H_%M_%S)
# ubuntu22="jammy-server-cloudimg-amd64.img"
# ubuntu20="focal-server-cloudimg-amd64.img"
# almalinux9="AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
# alpinelinux21="alpine-virt-3.21.3-x86.qcow2"
# centosstream9="CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"
# openwrt="openwrt-24.10.1-x86-generic-generic-ext4-combined-efi.qcow2"

echo -e "
###########################################################
#${blue}   __  __  ______   ______  ______  __  __  ______       ${reset}#
#${blue}  /\ \/\ \/\__  _\ /\  __ \/\__  _\/\ \/\ \/\__  _\      ${reset}#
#${blue}  \ \ \ \ \/_/\ \/ \ \ \_\ \/_/\ \/\ \ \ \ \/_/\ \/      ${reset}#
#${blue}   \ \ \ \ \ \ \ \  \ \ _  /  \ \ \ \ \ \ \ \ \ \ \      ${reset}#
#${blue}    \ \ \_/ \ \_\ \__\ \ \ \ \ \ \ \ \ \ \_\ \ \ \ \__   ${reset}#
#${blue}     \ \____/ /\______\ \_\ \_\ \ \_\ \ \_____\/\_____\  ${reset}#
#${blue}      \_____/ \/_____/ \/_/\/_/  \/_/  \/_____/\/_____/  ${reset}#
#${yellow}  Virtui v3 by uvewexyz                                  ${reset}#
###########################################################
"

# Start of the script
valid_start() {
  read -n 2 -e -i "Y" -p "Hello, Do you want to create a VM? (Y/n, default Y): " response;
  sleep 2;
  if [[ "${response}" != "Y" && "${response}" != "y" ]]; then
    echo "Goodbye...";
    sleep 2;
    exit 1;
  fi
}

valid_start;

# Check and validate this device support virtualization
valid_support() {
  echo "${line}"
  echo "Checking if your system support virtualization";
  if ! lscpu | grep "^Virtualization" > /dev/null 2>&1; then
    echo -e "${red}FAIL:${reset} Unseccessfully to start creating VM";
    echo -e "${blue}INFO:${reset} Your system does't support virtualization. You should check the BIOS configuration";
    exit 1;
  else
    echo -e "${green}SUCCESS:${reset} Successfully to start creating VM";
    echo -e "${blue}INFO:${reset} Your system support: 
    ${red}$(lscpu | grep "^Virtualization")${reset}";
    sleep 2 && clear;
  fi
}

valid_support;

# Check and validate libvirt dependencies package
valid_package() {
  echo "${line}"
  echo "Checking if the libvirt package dependencies have installed";
  declare -a packages=("cpu-checker" "ipcalc" "whois" "qemu-system" "libvirt-daemon-system" "virtinst")
  for pack in ${packages[@]}; do
    if [[ -z "$(sudo apt list --installed|grep "${pack}")" ]]; then
      echo -e "${blue}INFO:${reset} Package ${red}${pack}${reset} not found";
      sudo apt install ${pack} -y;
      clear;
    else
      echo -e "${blue}INFO:${reset} Package ${red}${pack}${reset} already exist";
      sleep 2 && clear;
    fi
  done
}

valid_package;

# Check and validate this device supporting nested virtualisation
valid_nested() {
  echo "${line}"
  echo "Checking if your system supports the nested virtualization";
  nested_module="$(lsmod | grep -E "^kvm_amd|^kvm_intel" | awk '{print $1}')"
  nested_value="$(cat /sys/module/${nested_module}/parameters/nested 2>/dev/null)"
  if [[ "${nested_value}" != "1" ]]; then
    echo -e "${blue}INFO:${reset} Nested virtualization is disabled";
    read -p "Do you want to enable nested virtualization? (Y/n, default Y): " nested_response;
    if [[ "${nested_response}" == "Y" ]]; then
      echo "Enabling nested virtualization...";
      echo "options ${nested_module} nested=1" | tee /etc/modprobe.d/kvm.conf;
      modprobe -r "${nested_module}";
      echo "${green}SUCCESS:${reset} Nested virtualization is enabled";
      sleep 2;
      clear;
    else
      echo -e "${red}FAIL:${reset} You can manually enable nested virtualization later";
      sleep 2;
      clear;
    fi
  else
    echo -e "${blue}INFO:${reset} Nested virtualization is enabled, ${red}value: ${nested_value}${reset}";
    sleep 2;
    clear;
  fi
}

valid_nested;

# Check and validate the user is member from libvirt group
valid_user() {
  echo "${line}"
  echo -e "Checking if the user ${red}$(whoami)${reset} is a member of the libvirt group";
  if [[ -z "$(id $USER -Gn|grep "libvirt$")" ]]; then
    echo -e "${blue}INFO:${reset} The ${red}$(whoami)${reset} user isn't a member of the libvirt";
    sleep 2;
    echo "Adding to the libvirt group";
    sudo usermod -aG libvirt $USER;
    id $USER -Gn|grep "libvirt$"
    if [[ -z "$(id $USER -Gn|grep "libvirt$")" ]]; then
      echo -e "${red}FAIL:${reset} Failed to add ${red}$(whoami)${reset} user to libvirt group";
      echo -e "${blue}INFO:${reset} Please fix the problem";
      exit 1;
    else
      echo -e "${green}SUCCESS:${reset} Now, the user ${red}$(whoami)${reset} is a member of the libvirt group";
      sleep 2;
      clear;
    fi
  else
    echo -e "${blue}INFO:${reset} The user ${red}$(whoami)${reset} is already a member of the libvirt group";
    sleep 2;
    clear;
  fi
}

valid_user;

# Validate workdir directory
valid_workdir() {
  echo "${line}"
  echo "Checking if your system has the workdir directory";
  if [[ ! -d "${dst_dir}" ]]; then
    sudo mkdir "${dst_dir}";
    if [[ ! -d "${dst_dir}" ]]; then
      echo -e "${red}FAIL:${reset} Failed to create directory";
      echo -e "${blue}INFO:${reset} Please fix the problem";
      exit 1;
    else
      echo -e "${green}SUCCESS:${reset} The ${red}${dst_dir}${reset} directory has been successfully created";
      sleep 2;
      clear;
    fi
  else
    echo -e "${blue}INFO:${reset} The ${red}${dst_dir}${reset} directory is already exists";
    sleep 2;
    clear;
  fi
}

valid_workdir;

# Validate if the VM name is ready to use
valid_name() {
  # Prompt to specify th VM name
  echo "${line}"
  read -e -i "vm$(date +%d_%m_%y)" -p "What is the VM name?: " vm_name;
  if virsh list --all --name | grep -qwF -- "${vm_name}"; then
    echo -e "${red}FAIL:${reset} This name is already use, please input again";
    sleep 3 && clear && valid_name;
  else
    echo -e "${blue}INFO:${reset} Saving a VM with the name ${red}${vm_name}${reset}";
    echo "${line}"
  fi
}

valid_name;

# Fill count the memory/RAM size to VM
valid_mem() {
  # Prompt to specify thre VM memory size
  vm_mem_max="$(grep -i "MemAvailable" /proc/meminfo | awk '{print $2/1048}' | cut -d. -f1)"
  echo -e "${blue}INFO:${reset} Total size memory available is ${red}${vm_mem_max}${reset} MiB";
  read -e -p "How much is the memory size you want allocated for your VM? (in MiB): " vm_mem;
  if [[ "${vm_mem}" -ge "${vm_mem_max}" ]]; then
    echo -e "${red}FAIL:${reset} Invalid memory size! Input below ${red}${vm_mem_max}${reset} MiB";
    echo "${line}";
    sleep 3;
    clear && valid_mem;
  else
    echo -e "${blue}INFO:${reset} Allocate memory with ${red}${vm_mem}${reset} MiB";
    echo "${line}";
  fi
}

valid_mem;

# Fill and allocate count vCPU to VM
valid_cpu() {
  # Prompt to specify the VM vCPU size
  echo -e "${blue}INFO:${reset} Total size cpu available is ${red}$(nproc)${reset} core";
  read -e -i "1" -p "How much is the cpu core you want allocated for your VM?: " vm_cpu;
  if [[ "${vm_cpu}" -lt 1  || "${vm_cpu}" -ge "$(nproc)" ]]; then
    echo -e "${red}FAIL:${reset} Invalid CPU size! Enter value between ${red}1${reset} core - ${red}$(nproc)${reset} core";
    echo "${line}";
    sleep 3;
    clear && valid_cpu;
  else
    echo -e "${blue}INFO:${reset} Allocate cpu with ${red}${vm_cpu}${reset} core";
    echo "${line}";
  fi
}

valid_cpu;

# Selecting the OS image 
valid_os_image() {
  # Listing available os images
  mapfile -t os_images < <(ls "${src_dir}");
  for os_image in "${!os_images[@]}"; do
    list=$(( os_image + 1 ));
    echo -e "${list}.) ${red}${os_images[os_image]}${reset}";
  done
  echo -e "${blue}INFO:${reset} Example selection is 1, 2, 3, or etc...";
  read -e -p "Selecting an OS for your VM (select the number): " vm_os;  
  if [[ "${vm_os}" -lt 1 && "${vm_os}" -gt "${#os_images[@]}" ]]; then
    echo -e "${red}FAIL:${reset} Invalid selection! Please select a number between 1 - ${#os_images[@]}";
    sleep 2 && valid_os_image;
  fi
  echo "${line}";
}

# # Selecting the OS to VM
# valid_os() {
#   # Prompt to select the OS for the VM
#   os_lists=("ubuntu22.04" "ubuntu20.04" "almalinux9" "alpinelinux3.21" "centos-stream9" "openwrt");
#   for os in "${!os_lists[@]}"; do
#     num=$((os + 1));
#     echo -e "${num}.) ${red}${os_lists[$os]}${reset}";
#   done
#   echo -e "${blue}INFO:${reset} Example selection is 1, 2, 3, or etc...";
#   read -e -p "Selecting an OS for your VM (select the number): " vm_os;
#   # The line below is used to debugging
#   # echo -e "Selecting the number: ${red}${vm_os}${reset}";
#   if [[ "${vm_os}" -lt 1 && "${vm_os}" -gt "${#os_lists[@]}" ]]; then
#     echo -e "${red}FAIL:${reset} Invalid selection! Please select a number between 1 and ${#os_lists[@]}";
#     sleep 2 && valid_os;
#   fi
# }

# Function to check available disk space in the storage pool
valid_disk_available() {
  for pool_storage in $(virsh pool-list --all --name); do 
    pool_dump=$(virsh pool-dumpxml --pool ${pool_storage} | awk -F"[<>]" '/path/{print $3}');
    disk_available=$(df -h ${pool_dump} | awk 'NR == 2 {print $1": "$4}');
    disk_available_array+=("${disk_available}");
    echo -e "${blue}INFO:${reset} Below is the information about available space";
    printf "%s\n" "${disk_available_array[@]}";
  done | sort -u
}

# Function to create, specify size, and formatting new disk images
valid_clone_image() {
  src_img=$1
  dst_img=$2
  dst_path="${dst_dir}/${dst_img}"
  # Clone process image from source image (-b option) and resulting the clone image
  qemu-img create -q -b "${src_dir}/${src_img}" -f qcow2 -F qcow2 "${dst_path}" "${vm_disk1_size}"G
  echo "${dst_path}"
}

# Specify the size of the primary disk
valid_primary_disk() {
  valid_os_image;
  valid_disk_available;
  echo -e "${yellow}TIPS:${reset} Fill in the below question with the number: ${red}1, 2, 3, or etc${reset}";
  read -e -i "15" -p "How much is the disk size you want allocated for your primary disk? (in GiB): " vm_disk1_size;
  # Validate the disk size input
  if [[ ! "${vm_disk1_size}" =~ ^[0-9]+$ || "${vm_disk1_size}" -lt 0 ]]; then
    echo -e "${red}FAIL:${reset} Invalid disk size! Please input a valid size number greater than 0";
    sleep 2 && clear && valid_primary_disk;
  else
    # Create clone image from source image
    echo -e "${blue}INFO:${reset} Proceeding to clone image"
    os=$(( "${vm_os}" - 1 ));
    vm_disk1=$(valid_clone_image "${os_images[${os}]}" "${os_images[${os}]}-$timestamp.img");
    # Validate if the clone image process successfully
    if [[ -e "${dst_path}" ]]; then
      # Show the primary disk image path
      echo -e "${red}FAIL:${reset} There are something problem, restart create primary disk";
      sleep 2 && clear && valid_primary_disk;
    else
      echo -e "${green}SUCCESS:${reset} The primary disk path is at ${red}${vm_disk1}${reset}";
    fi
  fi
  # Validate OS variant will be used
  vm_disk1_basename=$(basename "${vm_disk1}");
  patterns=();
  patterns+=($(echo "${vm_disk1_basename}" | awk -F'-' '{print $1}'));
  patterns+=($(echo "${vm_disk1_basename}" | awk -F'-' '{print $2}'));
  patterns+=($(echo "${vm_disk1_basename}" | awk -F'-' '{print $4}'));
  patterns+=($(echo "${vm_disk1_basename}" | grep -oP '[0-9]+\.[0-9]+'));
  # osinfo=$(osinfo-query os --fields=short-id,name,codename | grep -i "${patterns[0]}" | awk '{print $1}');
  # os_final=("${osinfo}");
  # List and split the OS name
  # while IFS= read -r oslist; do
  #   osfinal+=("${oslist}");
  # done < <(echo "${osinfo}");
  # Begin to match OS with available pattern
  osinfo=($(osinfo-query os --fields=short-id,name,codename | grep -i "${patterns[0]}" | awk '{print $1}'));
  osfinal=();
  # if [[ "${#osinfo[@]}" == 1 ]]; then
  #   osfinal+=("${osinfo[@]}");
  #   echo -e "${blue}INFO:${reset} ${red}${osfinal[@]}${reset}";
  # else
  #   for pattern1 in "${patterns[@]}"; do
  #     for pattern2 in "${patterns[@]}"; do
  #       osfilter=($(printf '%s\n' "${osinfo[@]}" | grep -i "${pattern1}" | grep -i "${pattern2}"));
  #       if [[ -n "${osfilter[@]}" || "${#osfilter[@]}" == 1 ]]; then
  #         osfinal+=("${osfilter[@]}");
  #         echo -e "${blue}INFO:${reset} ${red}${osfinal[@]}${reset}";
  #         break 2;
  #       fi
  #     done
  #   done
  # fi

  if [[ "${#osinfo[@]}" == 1 ]]; then
    osfinal+=("${osinfo[@]}");
    echo -e "${blue}INFO:${reset} ${red}${osfinal[@]}${reset}";
  else
    i=0;
    while [[ "${i}" -le "${#patterns[@]}" ]]; do
      filtered=($(printf '%s\n' "${osinfo[@]}" | grep -i "${patterns[$i]}"));
      if [[ "${#filtered[@]}" == 1 ]]; then
        osfinal+=("${filtered[@]}");
        echo -e "${blue}INFO:${reset} ${red}${osfinal[@]}${reset}";
        break;
      fi
      ((i++));
    done
  fi
  if [[ "${#filtered[@]}" -gt 1 ]]; then
    i=0;
    while [[ "${i}" -le "${#patterns[@]}" ]]; do
      filtered1=($(printf '%s\n' "${filtered[@]}" | grep -i "${patterns[$i]}"));
      if [[ "${#filtered1[@]}" == 1 ]]; then
        # unset osfinal;
        osfinal+=("${filtered1[@]}");
        echo -e "${blue}INFO:${reset} ${red}${osfinal[@]}${reset}";
        break;
      fi
      ((i++));
    done
  fi
  echo "${line}";
  # for pattern in "${patterns[@]}"; do
    # if [[ "${#osinfo[@]}" != 1 ]]; then
      # osfinal+=($(printf '%s\n' "${osinfo[@]}" | grep -i "${pattern}"));
      # echo "Pattern 0 & 1"
      # echo -e "${blue}INFO:${reset} ${red}${osfinal[@]}${reset}";
      # break;
    # else
      # osfinal=("${osinfo[@]}");
      # echo "Pattern 0"
      # echo -e "${blue}INFO:${reset} ${red}${osfinal[@]}${reset}";
      # break;
    # fi
  # done
}

valid_primary_disk;

# # Specify the size of the primary disk
# valid_os_disk() {
#   valid_os;
#   echo "${line}";
#   valid_disk_available;
#   echo -e "${yellow}TIPS:${reset} Fill in the below question with the number: ${red}1, 2, 3, or etc${reset}";
#   read -e -i "15" -p "How much is the disk size you want allocated for your primary disk? (in GiB): " vm_disk1_size;

#   # Validate the disk size input
#   if [[ ! "${vm_disk1_size}" =~ ^[0-9]+$ && "${vm_disk1_size}" -lt 0 ]]; then
#     echo -e "${red}FAIL:${reset} Invalid disk size! Please input a valid size number greater than 0";
#     sleep 2 && clear && valid_os_disk;
#   fi

#   case "${vm_os}" in
#     1)
#       vm_disk1=$(valid_copy_image "$ubuntu22" "ubuntu22-$timestamp.img")
#       ;;
#     2)
#       vm_disk1=$(valid_copy_image "$ubuntu20" "ubuntu20-$timestamp.img")
#       ;;
#     3)
#       vm_disk1=$(valid_copy_image "$almalinux9" "almalinux9-$timestamp.img")
#       ;;
#     4)
#       vm_disk1=$(valid_copy_image "$alpinelinux21" "alpinelinux21-$timestamp.img")
#       ;;
#     5)
#       vm_disk1=$(valid_copy_image "$centosstream9" "centosstream9-$timestamp.img")
#       ;;
#     6)
#       vm_disk1=$(valid_copy_image "$openwrt" "openwrt-$timestamp.img")
#       ;;
#     *)
#       echo "${red}FAIL:${reset} Option not found!. Please select between 1, 2, 3, 4, 5, or 6!!!"
#       exit 1
#       ;;
#   esac

#   # Show the primary disk image path
#   echo -e "${green}SUCCESS:${reset} The primary disk path is at ${red}${vm_disk1}${reset}";
#   echo "${line}"

#   case "${vm_os}" in
#     1)
#       vm_os="ubuntu22.04"
#       ;;
#     2)
#       vm_os="ubuntu20.04"
#       ;;
#     3)
#       vm_os="almalinux9"
#       ;;
#     4)
#       vm_os="alpinelinux3.21"
#       ;;
#     5)
#       vm_os="centos-stream9"
#       ;;
#     6)
#       vm_os="unknown"
#       ;;
#     *)
#       echo "${red}FAIL:${reset} Option not found!. Please select between 1, 2, 3, 4, 5, or 6!!!"
#       sleep 3;
#       clear && valid_os;
#       ;;
#   esac
# }

# valid_os_disk;

valid_peripheral_disk_size() {
  if [[ "${peripheral_disk_size}" =~ ^[0-9]+$ && "${peripheral_disk_size}" -gt 0 ]]; then
    disk_peripheral+=(--disk size="${peripheral_disk_size}");
  else
    echo "${red}FAIL:${reset} Invalid input size! Please input right size!";
    sleep 2 && valid_peripheral_disk_size;
  fi
}

valid_peripheral_disk_count() {
  echo -e "${blue}INFO:${reset} The peripheral disk will be the block device like: ${red}sdb, sdc, vdb, vdc, etc.${reset}";
  echo -e "${yellow}TIPS:${reset} Fill in the below question with the number: ${red}1, 2, 3, or etc${reset}";
  read -e -p "How many peripheral disk do you want to add to the VM?: " peripheral_disk_count;
  echo "${line}";
  if [[ "${peripheral_disk_count}" =~ ^[0-9]+$ && "${peripheral_disk_count}" -gt 0 ]]; then
    disk_peripheral=()
    echo -e "${yellow}TIPS:${reset} Fill in the below question with the number: ${red}1, 2, 3, or etc.${reset}";
    read -e -p "How much is the disk size you want allocated for your peripheral disk? (in GiB): " peripheral_disk_size;
    # Loop to create the specified number of peripheral disks
    for ((i = 1; i <= "${peripheral_disk_count}"; i++)); do
      valid_peripheral_disk_size;
    done
  else
    echo -e "${red}FAIL:${reset} Invalid count! Please input right number!";
    sleep 2 && clear && valid_peripheral_disk_count;
  fi
}

# Specify many peripheral disk to VM
valid_peripheral_disk() {
  valid_disk_available;
  read -e -p "Do you want to add many peripheral disk to the VM? (Y/n): " peripheral_disk_response;
  if [[ "${peripheral_disk_response}" != "Y" && "${peripheral_disk_response}" != "y" ]]; then
    echo -e "${blue}INFO:${reset} Not using the peripheral disk";
    sleep 2;
    echo "${line}";
  else
    echo "${line}";
    valid_peripheral_disk_count;
    echo "${line}";
  fi
}

valid_peripheral_disk;

# Validate attached virtual network and the interface on the hypervisor 
valid_vir_net() {
  # Declare arrays to keep the virtual network names and interfaces
  net_name=()
  net_if=()
  # Populate the arrays with values from the net var and the iface var
  for net in $(virsh net-list --all --name); do
    iface="$(virsh net-dumpxml ${net} | awk -F"'" '/bridge name=/{print $2}')";
    net_name+=("${net}")
    net_if+=("${iface}")
  done
  # Check if user haven't any virtual networks
  if [[ "${#net_name[@]}" -eq 0 ]]; then
    echo -e "${blue}INFO:${reset} Virtual networks not found. Please create a virtual network first.";
    exit 1;
  fi
  # List available virtual networks
  echo -e "${blue}INFO:${reset}";
  sleep 2;
  for vnet in "${!net_name[@]}"; do
    num=$((vnet + 1));
    echo -e "${num}.) Virtual Network: ${red}${net_name[${vnet}]}${reset} | Interface: ${red}${net_if[${vnet}]}${reset}";
  done
  # Prompt to select a virtual network
  echo -e "${yellow}TIPS:${reset} Fill in the below question with the number: ${red}1, 2, 3, or etc${reset}";
  read -e -p "Select the number of the virtual network to attach to the VM: " net_num;
  echo "${line}"
  sleep 2;
  # Validate the selected virtual network number
  if [[ "${net_num}" =~ ^[0-9]+$ && "${net_num}" -gt 0 && "${net_num}" -le "${#net_name[@]}" ]]; then
    vm_net_select="${net_name[$((net_num - 1))]}";
    vm_if_select="${net_if[${net_num} - 1]}";
    ip_gw="$(ip addr show ${vm_if_select} | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.1/g')";
    ip_start="$(ip addr show ${vm_if_select} | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.2/g')";
    ip_end="$(ip addr show ${vm_if_select} | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.254/g')";
    echo -e "${blue}INFO:${reset} You select vnet ${red}${vm_net_select}${reset} with interface: ${red}${vm_if_select}${reset}";
    echo -e "Your gateway is ${red}${ip_gw}${reset}";
    echo -e "Your ip address start from ${red}$ip_start${reset}";
    echo -e "Your ip address ended is ${red}$ip_end${reset}";
    echo -e "${yellow}TIPS:${reset} Fill above question with ip address, example ${red}$(ip addr show ${vm_if_select} | awk 'NR == 3 {print $2}' | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\/24/\1.10/g')${reset}";
  else
    echo -e "${red}FAIL:${reset} Invalid selection. Please select a valid number from the list.";
    sleep 3 && clear && valid_vir_net;
  fi
}

# Select IP Addr and validate the segmen IP
valid_ip() {
  ip_addr="${ip_gw%%/*}"
  ip_net="$(ipcalc -n "${ip_gw}" | awk -F: '/Network/ {gsub(/ /, "", $2); print $2}' | cut -d/ -f1)"
  netmask="$(ipcalc "${ip_gw}" | awk -F: '/Netmask/ {gsub(/ /, "", $2); print $2}' | cut -d= -f1)"
  # Prompt to assign a ip
  read -e -p "Assign the ip address to the VM: " ip_num;
  ip_input="$(ipcalc -n "${ip_num}" "${netmask}" | awk -F: '/Network/ {gsub(/ /, "", $2); print $2}' | cut -d/ -f1)"
  if [[ "${ip_input}" != "${ip_net}" ]]; then
    echo -e "${blue}INFO:${reset} IP address ${red}${ip_num}${reset} isn't in subnet ${red}${ip_net}${reset}! Please input again";
    sleep 3 && clear && valid_ip;
  else
    echo -e "${blue}INFO:${reset} Keep ip address is ${red}${ip_num}${reset}";
    echo "${line}"
  fi
}

# Validate login access to the VM using user or identity key
valid_access_login() {
  # Prompt to create a new user for the VM
  read -e -i "john" -p "Create a new user for the VM: " vm_user;
  echo "${line}";
  # Prompt to create a password for new user
  read -e -p "Create a password for the user: " vm_passwd;
  secret="$(echo "$vm_passwd" | mkpasswd -s --method=SHA-512 --rounds=500000)"
  echo "${line}";
  # Prompt to add public key SSH
  if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
    echo "${blue}INFO:${reset} Pubkey not found! Generating new pubkey...";
    sleep 2;
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -q;
  else
    echo -e "${blue}INFO:${reset} Pubkey found!";
    sleep 2;
  fi
  read -e -i "$(cat ~/.ssh/id_ed25519.pub)" -p "Add your pub key to the VM (Autofill): " vm_pubkey;
  echo "${line}";
}

# Process the VM creation
valid_processing_vm() {
  echo -e "${blue}INFO:${reset} Create VM name is ${red}${vm_name}${reset}";
  echo -e "${blue}INFO:${reset} VM OS is ${red}${vm_os}${reset}";
  echo "${line}"
  sleep 2;
  virt-install -q -n "${vm_name}" \
    --memory "${vm_mem}" \
    --vcpus "${vm_cpu}" \
    --import \
    --disk path="${vm_disk1}",format=qcow2 \
    "${disk_peripheral[@]}" \
    --cloud-init user-data="${dst_dir}"/"${vm_name}"-user-data \
    --osinfo detect=on,name="${osfinal[@]}" \
    --network bridge="${vm_if_select}" \
    --noautoconsole;
  sleep 2;
}

valid_cloud_init() {
  # Load the user-data file based on the selected OS
  # This is Ubuntu 22.04 and Ubuntu 20.04 user-data file
  if [[ "${vm_os}" == "ubuntu22.04" || "${vm_os}" == "ubuntu20.04" ]]; then
    valid_vir_net;
    valid_ip;
    valid_access_login;
    # Load config to Ubuntu user-data file
    cat << EOF > "${dst_dir}"/"${vm_name}"-user-data
#cloud-config

# Set hostname
hostname: ${vm_name}

# Configure users, groups, password
users:
  - name: ${vm_user}
    hashed_passwd: ${secret}
    shell: /bin/bash
    lock_passwd: false
    groups: sudo
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${vm_pubkey}

# Load network configuration
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
              - ${ip_num}/24
            nameservers:
              addresses: [8.8.8.8, 1.1.1.1]
            routes:
              - to: default
                via: ${ip_gw}

# Update, upgrade, and install packages
package_upgrade: true
package_update: true
packages:
- vim
- net-tools
- curl

runcmd:
  - chmod 600 /etc/netplan/99-custom-network.yaml
  - netplan apply
  - echo "AllowUsers ${vm_user}" >> /etc/ssh/sshd_config
  - sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  - systemctl restart sshd
  - systemctl restart NetworkManager
  - cloud-init status --wait
EOF
    valid_processing_vm;
  elif [[ "${vm_os}" == "almalinux9" || "${vm_os}" == "centos-stream9" ]]; then
    valid_vir_net;
    valid_ip;
    valid_access_login;
    # This is Alma Linux 9 and Centos Stream 9 user-data file
    cat << EOF > "${dst_dir}"/"${vm_name}"-user-data
#cloud-config

# Set hostname
hostname: ${vm_name}

# Configure users, groups, password
users:
  - name: ${vm_user}
    hashed_passwd: ${secret}
    shell: /bin/bash
    lock_passwd: false
    groups: sudo
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${vm_pubkey}

# Load network configuration
write_files:
  - path: /etc/sysconfig/network-scripts/ifcfg-eth0
    content: |
      IPADDR=${ip_num}
      NETMASK=${netmask}
      GATEWAY=${ip_gw}
      DNS1=8.8.8.8
      DNS2=1.1.1.1
      BOOTPROTO=static
      ONBOOT=yes
      DEVICE=eth0

# Update, upgrade, and install packages
package_upgrade: true
package_update: true

runcmd:
  - yum install vim net-tools curl -yq
  - echo "AllowUsers ${vm_user}" >> /etc/ssh/sshd_config
  - sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  - systemctl restart sshd
  - systemctl restart NetworkManager
  - systemctl enable nginx && systemctl start nginx
  - cloud-init status --wait
EOF
    valid_processing_vm;
  elif [[ "${vm_os}" == "alpinelinux3.21" ]]; then
    valid_vir_net;
    valid_ip;
    valid_access_login;
    # This is Alpine Linux 3.21 user-data file
    cat << EOF > "${dst_dir}"/"${vm_name}"-user-data
#cloud-config

# Set hostname
hostname: ${vm_name}

# Configure users, groups, password
users:
  - name: ${vm_user}
    hashed_passwd: ${secret}
    lock_passwd: false
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${vm_pubkey}

# Load network configuration
write_files:
  - path: /etc/apk/repositories
    content: |
      https://dl-cdn.alpinelinux.org/alpine/latest-stable/community
      https://dl-cdn.alpinelinux.org/alpine/latest-stable/main
    append: true
  - path: /etc/network/interfaces
    owner: root:root
    permissions: '0644'
    content: |
      auto eth0
      iface eth0 inet static
        address ${ip_num}
        netmask ${netmask}
        gateway ${ip_gw}
        dns-nameservers 8.8.8.8 1.1.1.1

# Update, upgrade, and install packages
package_upgrade: true
package_update: true

runcmd:
  - apk add vim curl net-tools openssh lsblk
  - rc-update add sshd
  - rc-service sshd start
  - echo "AllowUsers ${vm_user}" >> /etc/ssh/sshd_config
  - sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  - rc-service sshd restart
  - rc-service networking restart
EOF
    valid_processing_vm;
  else
    # This is OpenWRT section
    echo -e "${blue}INFO:${reset} OpenWRT isn't load your input ip address.
    This OS will be use selected network interface.
    You must manually configure the ip address after the VM is created.";
    echo "${line}"
    valid_vir_net;
    echo -e "Next to the process creating VM"
    sleep 2;
    echo "${line}"
    echo -e "Create VM name ${red}${vm_name}${reset}";
    echo -e "VM OS: ${red}${vm_os}${reset}";
    echo "${line}"
    sleep 2;
    virt-install -q -n "${vm_name}" \
      --memory "${vm_mem}" \
      --vcpus "${vm_cpu}" \
      --import \
      --disk path="${vm_disk1}",format=qcow2 \
      --osinfo detect=on,name="${vm_os}" \
      --network bridge="${vm_if_select}" \
      --noautoconsole;
    sleep 2;
  fi
}

valid_cloud_init;

# Validate if the VM is successfully created or not
valid_final_vm() {
  if virsh list --all --name | grep -qwF -- "${vm_name}"; then
    echo -e "${blue}INFO:${reset} Successfully created VM with name ${red}${vm_name}${reset}";
    virsh list --all | grep -i "${vm_name}";
  else
    echo "${red}FAIL:${reset} VM failed to create! There was an error during the process.";
    sleep 2;
    echo -e "${blue}INFO:${reset} You can check the ${red}journalctl -u libvirtd -xe${reset} for more details.";
    exit 1;
  fi
}

valid_final_vm;