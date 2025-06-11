###################
# Routing Resources
###################


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.test_network_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_network_igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.test_network_igw.id
  }

  tags = {
    Name               = "Network test public routing table"
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


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.test_network_vpc.id

  route {
    ipv6_cidr_block      = "::/0"
    network_interface_id = aws_instance.n5_gateway.primary_network_interface_id
  }

  tags = {
    Name               = "Network test private routing table"
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

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

output "private_rt" {
  description = "private routing table id"
  value       = aws_route_table.private.id
}

