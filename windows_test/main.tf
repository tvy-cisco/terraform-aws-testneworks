provider "aws" {
  profile = "strln"
  region  = "us-west-2"
}

data "aws_vpc" "terraform_vpc" {
  tags = {
    Name = "terraform-vpc"
  }
}
data "aws_subnet" "private_subnet_5" {
  tags = {
    Name = "terraform-Network5-private"
  }
}

data "aws_security_group" "test_instance" {
  tags = {
    Name = "terraform-Network5-test-sg"
  }
}

resource "aws_instance" "windows_test_instance" {
  ami                    = "ami-0c481fef9aec55a67" # Darren's Base Windows AMI
  instance_type          = "t3.medium"
  key_name               = "thomas_laptop"
  subnet_id              = data.aws_subnet.private_subnet_5.id
  vpc_security_group_ids = [data.aws_security_group.test_instance.id]

  tags = {
    Name = "WindowsEC2Instance"
  }
}

