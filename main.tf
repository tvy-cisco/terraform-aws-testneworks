provider "aws" {
  profile = "strln"
  region  = "us-west-2"
}

###################
# VPC Resources
###################

resource "aws_vpc" "terraform_vpc" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true


  tags = {
    Name = "terraform-vpc"
  }
}

resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "terraform-igw"
  }
}

###################
# Subnet Resources
###################

resource "aws_subnet" "public_subnet_5" {
  vpc_id                          = aws_vpc.terraform_vpc.id
  cidr_block                      = "10.0.1.0/24"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.terraform_vpc.ipv6_cidr_block, 8, 0)
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true
  availability_zone               = "us-west-2a"

  tags = {
    Name = "terraform-Network5-public"
  }
}

resource "aws_subnet" "private_subnet_5" {
  vpc_id                                         = aws_vpc.terraform_vpc.id
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.terraform_vpc.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation                = true
  ipv6_native                                    = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  availability_zone                              = "us-west-2a"

  tags = {
    Name = "terraform-Network5-private"
  }
}

###################
# Routing Resources
###################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main-igw.id
  }

  tags = {
    Name = "terraform-Network5-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    ipv6_cidr_block      = "::/0"
    network_interface_id = aws_instance.dns64_nat64.primary_network_interface_id
  }

  tags = {
    Name = "terraform-Network5-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet_5.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet_5.id
  route_table_id = aws_route_table.private.id
}

###################
# Security Groups
###################

resource "aws_security_group" "dns64_nat64" {
  name   = "terraform-Network5-dns64-nat64"
  vpc_id = aws_vpc.terraform_vpc.id

  # SSH access from specific IPs
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [
      "151.186.183.17/32",    # Added IP
      "151.186.183.81/32",    # Added IP
      "151.186.192.0/20"      # Added IP range
    ]
    description      = "SSH access from specific IPv4 addresses"
  }

  # DNS queries
  ingress {
    from_port        = 53
    to_port          = 53
    protocol         = "udp"
    ipv6_cidr_blocks = [aws_vpc.terraform_vpc.ipv6_cidr_block]
    description      = "DNS queries"
  }

    # Add TCP DNS for large responses
  ingress {
    from_port        = 53
    to_port          = 53
    protocol         = "tcp"
    ipv6_cidr_blocks = [aws_vpc.terraform_vpc.ipv6_cidr_block]
    description      = "DNS queries TCP from VPC"
  }

  # ICMPv6 (ping6)
  ingress {
    from_port        = -1
    to_port          = -1
    protocol         = "58"     # ICMPv6 protocol number
    ipv6_cidr_blocks = [aws_vpc.terraform_vpc.ipv6_cidr_block]
    description      = "ICMPv6 (ping6)"
  }

  # ICMPv4 (ping)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere
    description = "ICMP (ping)"
  }

  # All IPv6 traffic from VPC
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = [aws_vpc.terraform_vpc.ipv6_cidr_block]
    description      = "All IPv6 traffic from VPC"
  }

  # All outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }

  tags = {
    Name = "terraform-Network5-dns64-nat64-sg"
  }
}

resource "aws_security_group" "test_instance" {
  name   = "terraform-Network5-test"
  vpc_id = aws_vpc.terraform_vpc.id

  # SSH access
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    description      = "SSH access"
  }

  # ICMPv6 (ping6)
  ingress {
    from_port        = -1
    to_port          = -1
    protocol         = "58"  # ICMPv6 protocol number
    ipv6_cidr_blocks = ["::/0"]
    description      = "ICMPv6 (ping6)"
  }

  # DNS queries (for dig)
  egress {
    from_port        = 53
    to_port          = 53
    protocol         = "udp"
    ipv6_cidr_blocks = ["::/0"]
    description      = "DNS queries (UDP)"
  }
  
  egress {
    from_port        = 53
    to_port          = 53
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    description      = "DNS queries (TCP)"
  }

  # All outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }

  tags = {
    Name = "terraform-Network5-test-sg"
  }
}

###################
# Key Pair
###################

resource "aws_key_pair" "deployer" {
  key_name   = "terraform-network5-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4BHU0dKBfL6sFaFHdqHeQOrzj9cmAwWpLMAvN0DCys sshahary@cisco.com"
}

#resource "aws_key_pair" "thomas_key" {
#  key_name   = "thomas_key"
#  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGZx8IAu+Wki/2mmBDlj5ICeut+tsuPo8cu5tRC0tN4 tvy@cisco.com"
#}

###################
# EC2 Instances
###################

resource "aws_instance" "dns64_nat64" {
  ami                    = "ami-03e383d33727f4804" 
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public_subnet_5.id
  ipv6_address_count     = 1
  source_dest_check      = false # Required for NAT functionality
  vpc_security_group_ids = [aws_security_group.dns64_nat64.id]
  key_name               = aws_key_pair.deployer.key_name # Add this line

  user_data = file("${path.module}/scripts/dns64_nat64_setup.sh")

  tags = {
    Name = "terraform-Network5-dns64-nat64"
  }
}

resource "aws_instance" "test_instance" {
  ami                    = "ami-03e383d33727f4804"
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private_subnet_5.id
  ipv6_address_count     = 1
  vpc_security_group_ids = [aws_security_group.test_instance.id]
  key_name               = aws_key_pair.deployer.key_name // Changed to use the deployer key

  user_data = templatefile("${path.module}/scripts/test_instance_setup.sh.tpl", {
    dns64_server_ipv6 = aws_instance.dns64_nat64.ipv6_addresses[0]
  })

  tags = {
    Name = "terraform-Network5-test"
  }
}
###################
# Outputs
###################

output "nat64_server_ipv6" {
  description = "IPv6 address of the NAT64/DNS64 server"
  value       = aws_instance.dns64_nat64.ipv6_addresses[0]
}

output "nat64_server_ipv4" {
  description = "IPv4 address of the NAT64/DNS64 server"
  value       = aws_instance.dns64_nat64.public_ip
}

output "test_instance_ipv6" {
  description = "IPv6 address of the test instance"
  value       = aws_instance.test_instance.ipv6_addresses[0]
}

output "ssh_proxy_command_example" {
  description = "Example SSH ProxyCommand configuration for accessing the test instance via the NAT64 server."
  value       = <<EOT
To SSH into the test instance (private instance) via the NAT64 server (public bastion),
add the following to your ~/.ssh/config file:

Host nat64-server
  HostName ${aws_instance.dns64_nat64.public_ip}
  User admin # Or your instance's user, e.g., ec2-user
  # Add your IdentityFile if not default, e.g., IdentityFile ~/.ssh/terraform-network5-key

Host test-instance-private
  HostName ${aws_instance.test_instance.ipv6_addresses[0]} # Using IPv6 address
  User admin # Or your instance's user
  ProxyCommand ssh -W %h:%p nat64-server
  # Add your IdentityFile if not default, e.g., IdentityFile ~/.ssh/terraform-network5-key

Then you can connect using: ssh test-instance-private

Alternatively, for a one-time command:
ssh -o ProxyCommand="ssh -W %h:%p admin@${aws_instance.dns64_nat64.public_ip}" admin@${aws_instance.test_instance.ipv6_addresses[0]}
(Replace 'admin' with the correct username for your AMI if different, and ensure your SSH key is added to the ssh-agent or specified with -i)
EOT
}