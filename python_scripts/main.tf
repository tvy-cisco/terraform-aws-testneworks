provider "aws" {
  profile = "strln"
  region  = "us-west-2"
}

data "aws_instance" "mac_test_instance" {
  filter {
    name   = "tag:Name"
    values = ["Mac Test Instance"]
  }
}
output "mac_test_ip" {
  description = "Ipv6 address of mac test instance"
  value       = tolist(data.aws_instance.mac_test_instance.ipv6_addresses)[0]
}

data "aws_instance" "linux_test_instance" {
  filter {
    name   = "tag:Name"
    values = ["Linux Test Instance"]
  }
}

output "linux_test_ip" {
  description = "IPv6 address of the linux test instance"
  value       = tolist(data.aws_instance.linux_test_instance.ipv6_addresses)[0]
}

data "aws_instance" "windows_test_instance" {
  filter {
    name   = "tag:Name"
    values = ["Windows Test Instance"]
  }
}

output "windows_test_ip" {
  description = "IPv6 address of the windows test instance"
  value       = tolist(data.aws_instance.windows_test_instance.ipv6_addresses)[0]
}

data "aws_instance" "jumpbox" {
  filter {
    name   = "tag:Name"
    values = ["Jumpbox Instance"]
  }
}

output "jumpbox_ip" {
  description = "jumpbox output ipv4"
  value       = data.aws_instance.jumpbox.public_ip
}

data "aws_instance" "n5_gateway" {
  filter {
    name   = "tag:Name"
    values = ["Network 5 Gateway"]
  }
}

output "n5_gateway_ipv6" {
  description = "IPv6 address of the Network 5 gateway server"
  value       = tolist(data.aws_instance.n5_gateway.ipv6_addresses)[0]
}

output "n5_gateway_ipv4" {
  description = "IPv4 address of the Network 5 server"
  value       = data.aws_instance.n5_gateway.public_ip
}

output "n5_gateway_network_interface_id" {
  description = "Network interface id of n5 gateway"
  value       = data.aws_instance.n5_gateway.network_interface_id
}

data "aws_instance" "n4_gateway" {
  filter {
    name   = "tag:Name"
    values = ["Network 4 Gateway"]
  }
}

output "n4_gateway_ipv6" {
  description = "IPv6 address of the Network 5 gateway server"
  value       = tolist(data.aws_instance.n4_gateway.ipv6_addresses)[0]
}

output "n4_gateway_ipv4" {
  description = "IPv4 address of the Network 5 server"
  value       = data.aws_instance.n4_gateway.public_ip
}

output "n4_gateway_network_interface_id" {
  description = "Network interface id of n4 gateway"
  value       = data.aws_instance.n4_gateway.network_interface_id
}

data "aws_route_table" "private" {
  tags = {
    Name = "Network test private routing table"
  }
}

output "private_rt" {
  description = "private routing table id"
  value       = data.aws_route_table.private.id
}
