#!/bin/bash

# Exclude traffic to port 10022 from WireGuard
iptables -t mangle -A OUTPUT -p tcp --dport 10022 -j MARK --set-mark 1

# Exclude traffic to port 5999 from WireGuard
iptables -t mangle -A OUTPUT -p tcp --dport 5999 -j MARK --set-mark 1

# Do not route marked packets through WireGuard
ip rule add fwmark 1 table main
ip route flush cache

# Execute the main command
exec "$@"