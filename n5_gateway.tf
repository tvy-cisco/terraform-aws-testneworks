###################
# Security Groups
###################

resource "aws_security_group" "n5_gateway" {
  name   = "terraform-Network5-gateway-sg"
  vpc_id = aws_vpc.terraform_vpc.id

  # SSH access from specific IPs
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "151.186.183.17/32", # Added IP
      "151.186.183.81/32", # Added IP
      "151.186.192.0/20"   # Added IP range
    ]
    description = "SSH access from specific IPv4 addresses"
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
    protocol         = "58" # ICMPv6 protocol number
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



###################
# EC2 Instances
###################

resource "aws_instance" "n5_gateway" {
  ami                    = "ami-03e383d33727f4804"
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public_subnet.id
  ipv6_address_count     = 1
  source_dest_check      = false                                                                # Required for NAT functionality
  vpc_security_group_ids = [aws_security_group.n5_gateway.id, aws_security_group.jumpbox_sg.id] # jumpbox_sg 

  user_data = templatefile("${path.module}/scripts/n5_gateway_setup.sh.tpl", {
    deploy_ssh_keys_script = file("${path.module}/scripts/deploy_ssh_keys.sh")
  })

  tags = {
    Name = "terraform-Network5-dns64-nat64"
  }
}


output "n5_gateway_ipv6" {
  description = "IPv6 address of the Network 5 gateway server"
  value       = aws_instance.n5_gateway.ipv6_addresses[0]
}

output "n5_gateway_ipv4" {
  description = "IPv4 address of the Network 5 server"
  value       = aws_instance.n5_gateway.public_ip
}
