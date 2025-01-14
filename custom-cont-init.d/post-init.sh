#!/bin/bash
# Wait for WireGuard to initialize
echo "Waiting for WireGuard to initialize..."

while ! ip link show wg0 >/dev/null 2>&1; do
  sleep 1
done

echo "WireGuard interface wg0 is ready. Applying custom iptables rules..."

# Exclude outbound traffic on port 5999
iptables -t mangle -A OUTPUT -p tcp --dport 5999 -j MARK --set-mark 1

# Exclude inbound traffic on port 5999
iptables -t mangle -A PREROUTING -p tcp --dport 5999 -j MARK --set-mark 1

# Ensure marked traffic bypasses WireGuard
ip rule add fwmark 1 table main
ip route flush cache

echo "Custom iptables rules applied. Traffic to port 5999 will bypass the VPN."