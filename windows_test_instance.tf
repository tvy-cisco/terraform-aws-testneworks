resource "aws_instance" "windows_test_instance" {
  ami                    = "ami-0c481fef9aec55a67" # Darren's Base Windows AMI
  instance_type          = "m5.large"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.test_instance.id]

  tags = {
    Name               = "Windows Test Instance"
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

output "windows_test_ip" {
  description = "IPv6 address of the windows test instance"
  value       = aws_instance.windows_test_instance.ipv6_addresses[0]
}
