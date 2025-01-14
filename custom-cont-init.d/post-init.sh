#!/bin/bash

sleep 1

# Apply iptables rules for WireGuard routing
iptables -t nat -A POSTROUTING -s 172.20.0.0/24 -o wg0 -j MASQUERADE
iptables -A FORWARD -i wg0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT

# Log success
echo "iptables rules applied successfully"