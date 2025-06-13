resource "aws_instance" "mac_test_instance" {
  ami           = "ami-0e32721385a3683c5" # macOS AMI
  instance_type = "mac1.metal"
  # subnet_id              = aws_subnet.private_subnet.id
  # ipv6_address_count     = 1
  # vpc_security_group_ids = [aws_security_group.test_instance.id]
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]
  host_id                = "h-0f239ecaa8944a750"
  key_name               = aws_key_pair.manager.key_name
  user_data              = file("${path.module}/scripts/mac_deploy_ssh_keys.sh")

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
