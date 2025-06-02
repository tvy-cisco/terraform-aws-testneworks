
locals {
  gateway_network_interfaces = {
    "n5" = aws_instance.n5_gateway.primary_network_interface_id
    "n4" = aws_instance.n4_gateway.primary_network_interface_id
  }
}



resource "aws_route_table" "private" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    ipv6_cidr_block      = "::/0"
    network_interface_id = local.gateway_network_interfaces[var.selected_network]
  }

  tags = {
    Name = "terraform-Network5-private-rt"
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

resource "aws_security_group" "test_instance" {
  name   = "terraform-Network5-test"
  vpc_id = aws_vpc.terraform_vpc.id

  # All outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }

  # ICMPv6 (ping6)
  ingress {
    from_port        = -1
    to_port          = -1
    protocol         = "58" # ICMPv6 protocol number
    ipv6_cidr_blocks = ["::/0"]
    description      = "ICMPv6 (ping6)"
  }

  # Allow SSH from jumpbox security group
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = [aws_security_group.jumpbox_sg.id]
    description      = "SSH access from jumpbox security group"
  }

  #Allow RDP from jumpbox security group
  ingress {
    from_port       = 3389
    to_port         = 3389
    protocol        = "tcp"
    security_groups = [aws_security_group.jumpbox_sg.id]
    description     = "RDP access from jumpbox security group"
  }

  tags = {
    Name = "terraform-Network5-test-sg"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet_5.id
  route_table_id = aws_route_table.private.id
}

resource "aws_instance" "linux_test_instance" {
  ami                    = "ami-03e383d33727f4804"
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private_subnet_5.id
  ipv6_address_count     = 1
  vpc_security_group_ids = [aws_security_group.test_instance.id]

  user_data = templatefile("${path.module}/scripts/test_instance_setup.sh.tpl", {
    dns64_server_ipv6      = aws_instance.n5_gateway.ipv6_addresses[0],
    deploy_ssh_keys_script = file("${path.module}/scripts/deploy_ssh_keys.sh")
  })

  tags = {
    Name = "Linux Test Instance Network5"
  }
}

resource "aws_instance" "windows_test_instance_network5" {
  ami                    = "ami-0c481fef9aec55a67" # Darren's Base Windows AMI
  instance_type          = "m5.large"
  key_name               = "thomas_laptop"
  subnet_id              = aws_subnet.private_subnet_5.id
  vpc_security_group_ids = [aws_security_group.test_instance.id]

  user_data = templatefile("${path.module}/scripts/windows_test_instance_setup.ps1.tpl",
    {
      dns64_server_ipv6 = aws_instance.n5_gateway.ipv6_addresses[0]
  })
  tags = {
    Name = "Windows Test Instance Network5"
  }
}

output "windows_test_ip" {
  description = "IPv6 address of windows test instance"
  value       = aws_instance.windows_test_instance_network5.ipv6_addresses[0]
}
output "linux_test_ip" {
  description = "IPv6 address of the linux test instance"
  value       = aws_instance.linux_test_instance.ipv6_addresses[0]
}
