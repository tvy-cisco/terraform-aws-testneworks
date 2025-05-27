#!/bin/bash

# Update system and install test tools
sudo DEBIAN_FRONTEND=noninteractive apt-get update -yq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq dnsutils curl net-tools iputils-ping

# Back up original resolv.conf
sudo cp /etc/resolv.conf /etc/resolv.conf.backup

# Configure DNS to use NAT64/DNS64 server
sudo cat > /etc/resolv.conf <<EOF
nameserver ${dns64_server_ipv6}
EOF

# Create test script
cat > /home/ubuntu/test.sh <<'EOF'
#!/bin/bash

echo "Running Network 5 test cases..."

# Test DNS resolution
echo "Testing DNS resolution..."
dig a ipv4only.arpa
dig aaaa ipv4only.arpa

# Test HTTP access
echo "Testing HTTP access..."
curl -v http://ipv4.tlund.se/
curl -v http://ipv6.tlund.se/
curl -v http://dual.tlund.se/

# Test NAT64 mapping
echo "Testing NAT64 mapping..."
curl -v http://[64:ff9b::193.15.228.195]/

# Test IPv6-only resources
echo "Testing IPv6-only resources..."
curl -v http://[2a00:801:f::195]/
curl -v http://ipv6-only.tlund.se/
EOF

chmod +x /home/ubuntu/test.sh