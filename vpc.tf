
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

resource "aws_subnet" "public_subnet" {
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


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}






###################
# Outputs
###################




output "ssh_proxy_command_example" {
  description = "Example SSH ProxyCommand configuration for accessing the test instance via the NAT64 server."
  value       = <<EOT
To SSH into the test instance
Linux Test Instance via Network 5 Gateway server, use the following command:
ssh -o ProxyCommand="ssh -W [%h]:%p admin@${aws_instance.n5_gateway.public_ip}" admin@${aws_instance.linux_test_instance.ipv6_addresses[0]}
  
Linux Test Instance via Windows Jumpbox, use the following command:
ssh -o ProxyCommand="ssh -W [%h]:%p onprem-jenkins@${aws_instance.windows_jumpbox.public_ip}" admin@${aws_instance.linux_test_instance.ipv6_addresses[0]}
EOT
}

