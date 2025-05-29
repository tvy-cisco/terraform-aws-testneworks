resource "aws_instance" "windows_test_instance" {
  ami                    = "ami-0c481fef9aec55a67" # Darren's Base Windows AMI
  instance_type          = "m5.large"
  key_name               = "thomas_laptop"
  subnet_id              = aws_subnet.private_subnet_5.id
  vpc_security_group_ids = [aws_security_group.test_instance.id]

  user_data = templatefile("${path.module}/scripts/windows_test_instance_setup.ps1.tpl",
    {
      dns64_server_ipv6 = aws_instance.dns64_nat64.ipv6_addresses[0]
  })
  tags = {
    Name = "Windows Test Instance"
  }
}

output "windows_test_instance" {
  description = "windows test instance ipv6"
  value       = aws_instance.windows_test_instance.ipv6_addresses[0]
}
