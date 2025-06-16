resource "aws_key_pair" "manager" {
  key_name   = "manager_key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKN++QziJ4gQAmS351sWoVypHuo2lv6+4LTDfBSXPhb tvy@cisco.com"
}

