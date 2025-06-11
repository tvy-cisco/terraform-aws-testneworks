
Right now only Network 4 and Network 5 are supported (IPV6 only). https://confluence-eng-rtp2.cisco.com/conf/display/PROD/Test+Network+Design

Use `terraform init` to initialize the Terraform configuration.
Use `terraform plan` to see the changes that will be applied.
Use `terraform apply` to create the resources for test networks.
Use `terraform destroy` to remove the resources for the test networks.

Use `pip install -r python_scripts/requirements.txt` to install the required packages.
Use the `python ./python_scripts/network_switch.py {test_network_number}` command to switch between the test networks.
The python script will create ssh tunnels through the jumpbox for RDP and VNC.


### RDP / VNC into test instances
RDP Windows - localhost:7066
VNC MacOS - localhost:7077

### SSH into test instances
Make sure your ssh public keys are on the jumpbox and the test instance.
ssh -o ProxyCommand="ssh -W [%h]:%p admin@{jumpbox-ip}" test_instance_user@{test_instance_ip}
