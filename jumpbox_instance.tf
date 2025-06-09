
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
    cidr_blocks = ["151.186.192.0/20"]
    description = "SSH access VPN CIDR IPV4"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["173.38.117.64/27"]
    description = "SSH access Blizzard CIDR IPV4"
  }


  # IPV4 RDP access
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["151.186.192.0/20"]
    description = "RDP access VPN CIDR IPV4"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["173.38.117.64/27"]
    description = "RDP access Blizzard CIDR IPV4"
  }

  tags = {
    Name = "terraform-Network5-test-sg"
  }
}

resource "aws_instance" "windows_jumpbox" {
  ami                    = "ami-0c481fef9aec55a67" # Darren's Base Windows AMI
  instance_type          = "m5.large"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]

  user_data = file("${path.module}/scripts/deploy_ssh_keys.ps1")

  tags = {
    Name = "WindowsJumpboxInstance"
  }
}

output "jumpbox_ip" {
  description = "jumpbox output ipv4"
  value       = aws_instance.windows_jumpbox.public_ip
}
