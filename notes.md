#### If you consider to run this script rootless. First, you can do this. Add the `read` permission to other on the `images` directory
```bash
chmod o+r /var/lib/libvirt/images/
```
#### To manage virsh environment without rootless. You must uncomment this parameter
```bash
sed -i 's/^#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/g' /etc/libvirt/libvirtd.conf
```
#### Make to easy while change root pass. You can do this to other user
```bash
echo "user1:Str0ngPass!" | chpasswd
```

#### Notes

| Legend  | Colour
---------------------
| INFO    | Blue    |
| SUCCESS | Green   |
| FAIL    | Red     |
| TIPS    | Yellow  |

#### The process queue in the script:
```bash
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
- Check and validate the user is member from libvirt group
                |
                V
- Validate the `workdir` directory
                |
                V
- Validate if the VM name is ready to use
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
- Validate attached virtual network and the interface on the hypervisor
                |
                V
- Select IP Addr and validate the segmen IP
                |
                V
- Validate login access to the VM using user or identity key
                |
                V
- Load the user-data file based on the selected OS 
                |
                V
- The VM creation process
                |
                V
- Validate if the VM is successfully created or not
```