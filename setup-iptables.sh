#!/bin/bash

# Wait for WireGuard to initialize
echo "Waiting for WireGuard to initialize..."
sleep 10  # Adjust this if needed

# Exclude traffic to container port 10022 (host port 50922)
iptables -t mangle -A OUTPUT -p tcp --dport 10022 -j MARK --set-mark 1

# Exclude traffic to container port 5999
iptables -t mangle -A OUTPUT -p tcp --dport 5999 -j MARK --set-mark 1

# Do not route marked packets through WireGuard
ip rule add fwmark 1 table main
ip route flush cache

echo "Port exclusions applied. WireGuard configuration complete."