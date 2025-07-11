resource "aws_instance" "mac_test_instance" {
  ami                    = "ami-0ead100c37c030fe9" # macOS AMI
  instance_type          = "mac1.metal"
  subnet_id              = aws_subnet.private_subnet.id
  ipv6_address_count     = 1
  vpc_security_group_ids = [aws_security_group.test_instance.id]
  host_id                = "h-0f239ecaa8944a750"

  tags = {
    Name               = "Mac Test Instance"
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

output "mac_test_ip" {
  description = "Ipv6 address of mac test instance"
  value       = aws_instance.mac_test_instance.ipv6_addresses[0]
}

output "mac_ssh_through_jumpbox" {
  description = "Mac Ssh through jumpbox"
  value       = <<EOT
Mac Test Instance via Jumpbox, use the following command:
ssh -o ProxyCommand="ssh -W [%h]:%p admin@${aws_instance.jumpbox.public_ip}" ec2-user@${aws_instance.mac_test_instance.ipv6_addresses[0]}
EOT
}
