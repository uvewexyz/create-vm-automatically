The process queue in the script:

- Start of the script

        |
        V

- Collect variable

        |
        V

- Make sure user to continue run the script

        |
        V

- Prompt to specify VM name

        |
        V

- Prompt to specify VM memory size

        |
        V

- Prompt to specify VM vCPU size

        |
        V

- Prompt to specify VM OS

        |
        V

- Prompt to specify the size of the primary disk

        |
        V

- Prompt to specify the size of the secondary disk

        |
        V

- Prompt to specify a virtual network

        |
        V

- Prompt to assign a ip address

        |
        V

- Prompt to add customize new user

        |
        V

- Prompt to create a password for new user

        |
        V

- Prompt to add public key SSH

        |
        V

- Load config to user-data file

        |
        V

- Process the VM creation

        |
        V

Validate if the VM is already created

                |
                |
=| success |=--------=| failed |=
        |               |
        V               V
      Done      Exit script, run script again