#!/bin/bash
# Wait for WireGuard interface (wg0) to be ready
echo "Waiting for WireGuard to initialize..."

# Loop until the WireGuard interface is up
while ! ip link show wg0 >/dev/null 2>&1; do
  sleep 1
done

echo "WireGuard interface wg0 is ready. Applying custom iptables rules..."

# Exclude traffic to container port 10022 (mapped to host port 50922)
iptables -t mangle -A OUTPUT -p tcp --dport 10022 -j MARK --set-mark 1

# Exclude traffic to container port 5999
iptables -t mangle -A OUTPUT -p tcp --dport 5999 -j MARK --set-mark 1

# Do not route marked packets through WireGuard
ip rule add fwmark 1 table main
ip route flush cache

echo "Custom iptables rules applied. Traffic to ports 10022 and 5999 will bypass the VPN."