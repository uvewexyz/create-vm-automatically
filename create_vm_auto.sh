#!/bin/bash


ubuntu22="/tmp/<image_dir>/<your_ubuntu22.img>"
ubuntu20="/tmp/<image_dir>/<your_ubuntu20.img>"
almalinux9="/tmp/<image_dir>/<your_almaLinux9.img>"
centosstream9="/tmp/<image_dir>/<your_centos-stream9.img>"
openwrt="/tmp/<image_dir>/<your_openwrt.img>"


echo "-------------------------------------------------------------------------------------"
read -n 1 -e -i "Y" -p "Welcome, this is the script to create a VM. Want to continue? (Y/n, default yes) : " RESPONSE;
echo "-------------------------------------------------------------------------------------"
sleep 1;

if [[ "$RESPONSE" != "Y" && "$RESPONSE" != "y" ]]; then

  echo "Goodbye...";
  exit 1;

fi

read -e -i "my-vm$(date +%d_%m_%y)" -p "Create the VM name: " VMNAME;
echo "-------------------------------------------------------------------------------------"

read -e -i "512" -p "Size memory to allocate for the VM, in MiB: " VMMEMORY;
echo "-------------------------------------------------------------------------------------"

read -e -i "1" -p "Size of virtual cpus for the VM: " VMVCPU;
echo "-------------------------------------------------------------------------------------"

echo -e "
1.) ubuntu22
2.) ubuntu20
3.) almalinux9
4.) centosstream9
5.) openwrt
-------------------------------------------------------------------------------------\n"
read -e -n 1 -i "5" -p "Select number of the menu to your VM OS: " VMOS;
echo "-------------------------------------------------------------------------------------"

read -e -i "5" -p "Allocacte new secondary disk image in Gigabyte to the VM: " VMDISK2;
echo "-------------------------------------------------------------------------------------"

sleep 1;

if virsh list --all --name | grep -qwF -- "$VMNAME"; then

  echo "-------------------------------------------------------------------------------------"
  echo "This name is already use, exit script...";
  echo "-------------------------------------------------------------------------------------"
  exit 1;

elif [[ "$VMOS" == "1" ]]; then
  
  echo "-------------------------------------------------------------------------------------"
  echo "Create VM name '$VMNAME' "
  echo "-------------------------------------------------------------------------------------"
  sleep 2;
  virt-install -n $VMNAME --memory $VMMEMORY --vcpus $VMVCPU --import --disk $ubuntu22 --disk size=$VMDISK2  --os-variant detect=on --network bridge=$(virsh net-list --all |awk '{print $1}'|sed -n '3p') --noautoconsole;
  echo "Result: "
  sleep 2;
  virsh list --all;
  sleep 2;
  echo "-------------------------------------------------------------------------------------"
  echo "Successfully create VM, see you... "
  echo "-------------------------------------------------------------------------------------"

elif [[ "$VMOS" == "2" ]]; then

  echo "-------------------------------------------------------------------------------------"
  echo "Create VM name '$VMNAME' "
  echo "-------------------------------------------------------------------------------------"
  sleep 2;
  virt-install -n $VMNAME --memory $VMMEMORY --vcpus $VMVCPU --import --disk $ubuntu20 --disk size=$VMDISK2  --os-variant detect=on --network bridge=$(virsh net-list --all |awk '{print $1}'|sed -n '3p') --noautoconsole;
  echo "Result: "
  sleep 2;
  virsh list --all;
  sleep 2;
  echo "-------------------------------------------------------------------------------------"
  echo "Successfully create VM, see you... "
  echo "-------------------------------------------------------------------------------------"

elif [[ "$VMOS" == "3" ]]; then

  echo "-------------------------------------------------------------------------------------"
  echo "Create VM name '$VMNAME' "
  echo "-------------------------------------------------------------------------------------"
  sleep 2;
  virt-install -n $VMNAME --memory $VMMEMORY --vcpus $VMVCPU --import --disk $almalinux9 --disk size=$VMDISK2  --os-variant detect=on --network bridge=$(virsh net-list --all |awk '{print $1}'|sed -n '3p') --noautoconsole;
  echo "Result: "
  sleep 2;
  virsh list --all;
  sleep 2;
  echo "-------------------------------------------------------------------------------------"
  echo "Successfully create VM, see you... "
  echo "-------------------------------------------------------------------------------------"

elif [[ "$VMOS" == "4" ]]; then

  echo "-------------------------------------------------------------------------------------"
  echo "Create VM name '$VMNAME' "
  echo "-------------------------------------------------------------------------------------"
  sleep 2;
  virt-install -n $VMNAME --memory $VMMEMORY --vcpus $VMVCPU --import --disk $centosstream9 --disk size=$VMDISK2  --os-variant detect=on --network bridge=$(virsh net-list --all |awk '{print $1}'|sed -n '3p') --noautoconsole;
  echo "Result: "
  sleep 2;
  virsh list --all;
  sleep 2;
  echo "-------------------------------------------------------------------------------------"
  echo "Successfully create VM, see you... "
  echo "-------------------------------------------------------------------------------------"

elif [[ "$VMOS" == "5" ]]; then

  echo "-------------------------------------------------------------------------------------"
  echo "Create VM name '$VMNAME' "
  echo "-------------------------------------------------------------------------------------"
  sleep 2;
  virt-install -n $VMNAME --memory $VMMEMORY --vcpus $VMVCPU --import --disk $openwrt --disk size=$VMDISK2  --os-variant detect=on --network bridge=$(virsh net-list --all |awk '{print $1}'|sed -n '3p') --noautoconsole;
  echo "Result: "
  sleep 2;
  virsh list --all;
  sleep 2;
  echo "-------------------------------------------------------------------------------------"
  echo "Successfully create VM, see you... "
  echo "-------------------------------------------------------------------------------------"

else

  echo "Option not found!. Please select 1, 2, 3, 4, or 5!!!"
  exit 1;

fi

