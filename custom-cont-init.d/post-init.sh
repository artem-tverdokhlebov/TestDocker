#!/bin/bash

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Add a routing table for local traffic
ip rule add table 100 from 10.7.0.62
ip route add local 0.0.0.0/0 dev lo table 100

# Exclude VNC traffic (port 5901) from WireGuard
iptables -t mangle -A OUTPUT -p tcp --dport 5901 -j MARK --set-mark 1
ip rule add fwmark 1 table main

# Optional: Save iptables rules persistently
iptables-save > /etc/iptables/rules.v4

echo "Post-init script executed successfully!"