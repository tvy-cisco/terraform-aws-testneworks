#!/bin/bash

ssh_keys=(
"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGZx8IAu+Wki/2mmBDlj5ICeut+tsuPo8cu5tRC0tN4 tvy@cisco.com"
"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4BHU0dKBfL6sFaFHdqHeQOrzj9cmAwWpLMAvN0DCys sshahary@cisco.com"
)

mkdir -p /home/ec2-user/.ssh
for key in "${ssh_keys[@]}"; do
  echo "${key}" >> /home/ec2-user/.ssh/authorized_keys
done
chown -R ec2-user:ec2-user /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys
chmod 700 /home/ec2-user/.ssh
