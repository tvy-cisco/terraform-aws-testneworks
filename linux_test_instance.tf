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
    Name               = "Linux Test Instance"
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

output "linux_test_ip" {
  description = "IPv6 address of the linux test instance"
  value       = aws_instance.linux_test_instance.ipv6_addresses[0]
}
