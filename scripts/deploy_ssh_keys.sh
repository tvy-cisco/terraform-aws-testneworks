#!/bin/bash

ssh_keys=(
"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGZx8IAu+Wki/2mmBDlj5ICeut+tsuPo8cu5tRC0tN4 tvy@cisco.com"
"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4BHU0dKBfL6sFaFHdqHeQOrzj9cmAwWpLMAvN0DCys sshahary@cisco.com"
"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKN++QziJ4gQAmS351sWoVypHuo2lv6+4LTDfBSXPhb tvy@cisco.com"
)

mkdir -p /home/admin/.ssh
for key in "${ssh_keys[@]}"; do
  echo "${key}" >> /home/admin/.ssh/authorized_keys
done
chown -R admin:admin /home/admin/.ssh
chmod 600 /home/admin/.ssh/authorized_keys
chmod 700 /home/admin/.ssh
