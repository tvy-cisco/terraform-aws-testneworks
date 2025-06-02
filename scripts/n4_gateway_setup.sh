#!/bin/bash

# Update system and install required packages
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get install -y unbound tayga net-tools iptables-persistent dnsutils

# Define the primary network interface
PRIMARY_INTERFACE="ens5"
echo "Using primary interface: $PRIMARY_INTERFACE"

# Get instance IPv6 address
IPV6_ADDR=$(ip -6 addr show dev $PRIMARY_INTERFACE scope global | grep inet6 | awk '{print $2}' | cut -d'/' -f1)
if [ -z "$IPV6_ADDR" ]; then
    echo "Error: Could not detect IPv6 address on $PRIMARY_INTERFACE. Exiting."
    exit 1
fi
echo "Detected IPv6 address: $IPV6_ADDR"

# Configure Unbound for DNS64
cat > /etc/unbound/unbound.conf <<'EOF'
server:
    interface: ::0
    access-control: ::/0 allow
    do-ip4: yes
    do-ip6: yes
    do-udp: yes
    do-tcp: yes
    dns64-prefix: 64:ff9b::/96
    dns64-synthall: yes
    module-config: "dns64 validator iterator"
EOF

# Configure Tayga for NAT64
# Ensure data-dir is specified and directory exists with correct permissions if not using default
cat > /etc/tayga.conf <<EOF
tun-device nat64
ipv4-addr 192.168.255.1
prefix 64:ff9b::/96
ipv6-addr ${IPV6_ADDR}
dynamic-pool 192.168.255.0/24
data-dir /var/spool/tayga
EOF

# Create Tayga data directory
mkdir -p /var/spool/tayga
chown _tayga:_tayga /var/spool/tayga || true # Allow to fail if user _tayga doesn't exist yet or perms are already ok

# Enable IPv4 and IPv6 forwarding
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/30-ipv4-forward.conf
echo 'net.ipv6.conf.all.forwarding=1' | sudo tee /etc/sysctl.d/30-ipv6-forward.conf
sudo sysctl -p /etc/sysctl.d/30-ipv4-forward.conf
sudo sysctl -p /etc/sysctl.d/30-ipv6-forward.conf

# Configure Tayga TUN interface (manual steps, often handled by Tayga service if available)
# tayga --mktun # This is often done by the init script/service
# ip link set nat64 up
# ip addr add 192.168.255.1 dev nat64
# ip -6 addr add 64:ff9b::192.168.255.1/96 dev nat64 # This address is for the kernel side of the tunnel

# Add routing rules (manual steps, often handled by Tayga service if available)
# ip route add 192.168.255.0/24 dev nat64
# ip -6 route add 64:ff9b::/96 dev nat64

# Add iptables rules for NAT64 (IPv4 NAT)
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o $PRIMARY_INTERFACE -s 192.168.255.0/24 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4


# Start services using systemd if available, which is preferred
# The Tayga package for Debian/Ubuntu should provide a systemd service.
# These services usually handle TUN creation, IP assignment, and routing.

systemctl enable unbound
systemctl restart unbound

systemctl enable tayga
systemctl restart tayga

# Add to your setup script - simple validation
echo "Validating setup..."
systemctl is-active unbound || echo "WARNING: Unbound not running"
systemctl is-active tayga || echo "WARNING: Tayga not running"
ip link show nat64 || echo "WARNING: NAT64 interface not found"

# Add to NAT64 instance for easy debugging
cat > /home/admin/status.sh <<'EOF'
#!/bin/bash
echo "=== NAT64/DNS64 Status ==="
echo "Unbound: $(systemctl is-active unbound)"
echo "Tayga: $(systemctl is-active tayga)"
echo "NAT64 interface: $(ip link show nat64 2>/dev/null | grep UP || echo "DOWN")"
echo "IPv6 forwarding: $(cat /proc/sys/net/ipv6/conf/all/forwarding)"
EOF

echo "NAT64/DNS64 setup script finished."