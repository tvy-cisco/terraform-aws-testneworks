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
  ipv6_cidr_block                = cidrsubnet(aws_vpc.terraform_vpc.ipv6_cidr_block, 8, 0)
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true
  availability_zone               = "us-west-2a"

  tags = {
    Name = "terraform-Network5-public"
  }
}

resource "aws_subnet" "private_subnet_5" {
  vpc_id                          = aws_vpc.terraform_vpc.id
  ipv6_cidr_block                = cidrsubnet(aws_vpc.terraform_vpc.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation = true
  ipv6_native                     = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  availability_zone               = "us-west-2a" 

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
    ipv6_cidr_block = "::/0"
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
  name        = "terraform-Network5-dns64-nat64"
  vpc_id      = aws_vpc.terraform_vpc.id

  # SSH access from specific IP
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["66.249.77.67/32"]  # The specific IPv4 address
    description      = "SSH access from specific IPv4 address"
  }

  # DNS queries
  ingress {
    from_port        = 53
    to_port          = 53
    protocol         = "udp"
    ipv6_cidr_blocks = [aws_vpc.terraform_vpc.ipv6_cidr_block]
    description      = "DNS queries"
  }

  # ICMPv6 (ping6)
  ingress {
    from_port        = -1
    to_port          = -1
    protocol         = "58"  # ICMPv6 protocol number
    ipv6_cidr_blocks = ["::/0"]  # Allow from anywhere
    description      = "ICMPv6 (ping6)"
  }

  # ICMPv4 (ping)
  ingress {
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]  # Allow from anywhere
    description      = "ICMP (ping)"
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
  name        = "terraform-Network5-test"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    description      = "SSH access"
  }

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
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4BHU0dKBfL6sFaFHdqHeQOrzj9cmAwWpLMAvN0DCys sshahary@cisco.com" # Replace with your actual public key
}

###################
# EC2 Instances
###################

resource "aws_instance" "dns64_nat64" {
  ami                    = "ami-0735c191cf914754d"  # Ubuntu 22.04 LTS
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public_subnet_5.id
  ipv6_address_count     = 1
  source_dest_check      = false  # Required for NAT functionality
  vpc_security_group_ids = [aws_security_group.dns64_nat64.id]
  key_name               = aws_key_pair.deployer.key_name  # Add this line

  user_data = file("${path.module}/scripts/dns64_nat64_setup.sh")

  tags = {
    Name = "terraform-Network5-dns64-nat64"
  }
}

resource "aws_instance" "test_instance" {
  ami                    = "ami-0735c191cf914754d"  # Ubuntu 22.04 LTS
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private_subnet_5.id
  ipv6_address_count     = 1
  vpc_security_group_ids = [aws_security_group.test_instance.id]
  key_name               = aws_key_pair.deployer.key_name  # Add this line

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

output "test_instance_ipv6" {
  description = "IPv6 address of the test instance"
  value       = aws_instance.test_instance.ipv6_addresses[0]
}