
resource "aws_security_group" "jumpbox_sg" {
  name   = "jumpbox_sg"
  vpc_id = aws_vpc.test_network_vpc.id

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
    Name               = "Jumpbox Security Group"
    ProductFamilyName  = "DNS SEC"
    ApplicationName    = "OPI"
    Environment        = "Non-Prod"
    CiscoMailAlias     = "umbrell-opi-cicd@cisco.com"
    DataClassification = "Cisco Highly Confidential"
    DataTaxonomy       = "Cisco Strategic Data"
    ResourceOwner      = "Umbrella"
    TeamName           = "ERC"
    TechnicalContact   = "aturino@cisco.com"
    SecurityContact    = "aturino@cisco.com"
    IntendedPublic     = "False"
    LastRevalidatedBy  = "darhunt@cisco.com"
    LastRevalidatedAt  = formatdate("YYYY MMM DD", timestamp())
  }
}

resource "aws_instance" "jumpbox" {
  ami                    = "ami-03e383d33727f4804" #AWS Debian image
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]
  user_data              = file("${path.module}/scripts/deploy_ssh_keys.sh")

  tags = {
    Name               = "Jumpbox Instance"
    ProductFamilyName  = "DNS SEC"
    ApplicationName    = "OPI"
    Environment        = "Non-Prod"
    CiscoMailAlias     = "umbrell-opi-cicd@cisco.com"
    DataClassification = "Cisco Highly Confidential"
    DataTaxonomy       = "Cisco Strategic Data"
    ResourceOwner      = "Umbrella"
    TeamName           = "ERC"
    TechnicalContact   = "aturino@cisco.com"
    SecurityContact    = "aturino@cisco.com"
    IntendedPublic     = "False"
    LastRevalidatedBy  = "darhunt@cisco.com"
    LastRevalidatedAt  = formatdate("YYYY MMM DD", timestamp())
  }
}

output "jumpbox_ip" {
  description = "jumpbox output ipv4"
  value       = aws_instance.jumpbox.public_ip
}
