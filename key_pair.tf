resource "aws_key_pair" "manager" {
  key_name   = "manager_key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGZx8IAu+Wki/2mmBDlj5ICeut+tsuPo8cu5tRC0tN4 tvy@cisco.com"
}

