
resource "aws_security_group" "jumpbox_sg" {
  name   = "jumpbox_sg"
  vpc_id = aws_vpc.terraform_vpc.id

  # All outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  # IPV4 SSH access 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["151.186.183.17/32", "151.186.183.81/32", "151.186.192.0/20"]
    description = "SSH access VPN CIDR IPV4"
  }


  # IPV4 RDP access
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["151.186.183.17/32", "151.186.183.81/32", "151.186.192.0/20"]
    description = "RDP access VPN CIDR IPV4"
  }

  tags = {
    Name = "terraform-Network5-test-sg"
  }
}

resource "aws_instance" "windows_jumpbox" {
  ami                    = "ami-0c481fef9aec55a67" # Darren's Base Windows AMI
  instance_type          = "m5.large"
  key_name               = "thomas_laptop"
  subnet_id              = aws_subnet.public_subnet_5.id
  vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]

  tags = {
    Name = "WindowsJumpboxInstance"
  }
}

output "jumpbox_output" {
  description = "jumpbox output ipv4"
  value       = aws_instance.windows_jumpbox.public_ip
}
