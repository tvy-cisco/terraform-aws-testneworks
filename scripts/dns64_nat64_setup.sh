#!/usr/bin/env bash
set -euo pipefail

# Update system and install required packages
apt-get update
apt-get install -y unbound tayga net-tools iptables-persistent

# Determine the primary network interface (AWS uses ens5, ena0, etc. instead of eth0)
PRIMARY_INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
if [ -z "$PRIMARY_INTERFACE" ]; then
    # Fallback if no IPv4 route exists
    PRIMARY_INTERFACE=$(ip -o -6 route show to default | awk '{print $5}')
fi
if [ -z "$PRIMARY_INTERFACE" ]; then
    # Last resort fallback
    PRIMARY_INTERFACE=$(ip link | grep -v lo | grep -v "LOOPBACK" | grep "state UP" | head -n1 | awk -F': ' '{print $2}')
fi

echo "Detected primary interface: $PRIMARY_INTERFACE"

# Get instance IPv6 address
IPV6_ADDR=$(ip -6 addr show dev $PRIMARY_INTERFACE scope global | grep inet6 | awk '{print $2}' | cut -d'/' -f1)
if [ -z "$IPV6_ADDR" ]; then
    echo "Error: Could not detect IPv6 address. Exiting."
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
    hide-identity: yes
    hide-version: yes
    dns64-prefix: 2001:db8:1::/96
    dns64-synthall: yes
    module-config: "validator dns64 iterator"
EOF

mkdir -p /var/spool/tayga

# Configure Tayga for NAT64
cat > /etc/tayga.conf <<EOF
tun-device nat64
ipv4-addr 192.168.255.1
prefix 2001:db8:1::/96
# Assign a unique IPv6 address from the NAT64 prefix for the NAT64 interface
ipv6-addr 2001:db8:1::1
dynamic-pool 192.168.255.0/24
data-dir /var/spool/tayga
EOF

# Enable IPv6 forwarding
echo 'net.ipv6.conf.all.forwarding=1' > /etc/sysctl.d/30-ipv6-forward.conf
sysctl -p /etc/sysctl.d/30-ipv6-forward.conf

# Configure and start Tayga
if ! ip link show nat64 &>/dev/null; then
    tayga --mktun
fi
ip link set nat64 up
ip addr add 192.168.255.1 dev nat64 || true
ip -6 addr add 2001:db8:1::1/96 dev nat64 || true

# Add routing rules
ip route add 192.168.255.0/24 dev nat64 || true
ip -6 route add 2001:db8:1::/96 dev nat64 || true

# Add iptables rules for NAT64
iptables -t nat -A POSTROUTING -o $PRIMARY_INTERFACE -j MASQUERADE
iptables-save > /etc/iptables/rules.v4

# Add ip6tables rules if needed (NAT for IPv6 may not be supported)
if ip6tables -t nat -L &>/dev/null; then
    ip6tables -t nat -A POSTROUTING -o $PRIMARY_INTERFACE -j MASQUERADE
fi
ip6tables -A FORWARD -i $PRIMARY_INTERFACE -o nat64 -j ACCEPT
ip6tables -A FORWARD -o $PRIMARY_INTERFACE -i nat64 -j ACCEPT
ip6tables-save > /etc/iptables/rules.v6

# Start Tayga daemon
tayga

# Restart Unbound
if systemctl is-active --quiet unbound; then
    systemctl restart unbound
else
    systemctl start unbound
fi
