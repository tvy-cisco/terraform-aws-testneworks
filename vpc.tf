###################
# VPC Resources
###################

resource "aws_vpc" "test_network_vpc" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true


  tags = {
    Name               = "Network Test VPC"
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

resource "aws_internet_gateway" "test_network_igw" {
  vpc_id = aws_vpc.test_network_vpc.id

  tags = {
    Name               = "Network Test IGW"
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



###################
# Outputs
###################

output "ssh_proxy_command_example" {
  description = "Example SSH ProxyCommand configuration for accessing the test instance via the NAT64 server."
  value       = <<EOT
To SSH into the test instance
  Linux Test Instance via Windows Jumpbox, use the following command:
ssh -o ProxyCommand="ssh -W [%h]:%p admin@${aws_instance.jumpbox.public_ip}" admin@${aws_instance.linux_test_instance.ipv6_addresses[0]}
EOT
}

