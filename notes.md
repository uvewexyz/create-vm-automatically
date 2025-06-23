# If you consider to run this script rootless
# First, you can do this
# Add the `read` permission to other on the `images` directory
chmod o+r /var/lib/libvirt/images/

# To manage virsh environment without rootless
# You must uncomment this parameter
sed -i 's/^#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/g' /etc/libvirt/libvirtd.conf

# Make to easy while change root pass
# You can do this to other user 
echo "user1:Str0ngPass!" | chpasswd

# The process queue in the script:

- Start of the script

        |
        V

- Check and validate this device support virtualization 

        |
        V

- Check and validate libvirt dependencies package

        |
        V

- Check and validate this device supporting nested virtualisation

        |
        V

- Check and validate the user is added to libvirt group

        |
        V

- Validate the `workdir` directory

        |
        V

- Fill count the memory/RAM size to VM 

        |
        V

- Fill and allocate count vCPU to VM

        |
        V

- Selecting the OS to VM

        |
        V

- Specify the size of the primary disk

        |
        V

- Specify the size of the secondary disk

        |
        V

- Check and validate virtual network on hypervisor

        |
        V

- Select IP Addr and validate the segmen IP

        |
        V

- Load the user-data file based on the selected OS 

        |
        V

- VM creation process

        |
        V

Validate if the VM is already created