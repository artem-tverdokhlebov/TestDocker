#!/bin/bash

# Function to check if the WireGuard interface is active
wait_for_wireguard() {
    local interface="wg0"
    local retries=10
    local wait_time=2

    echo "Waiting for WireGuard interface ($interface) to initialize..."
    while [ $retries -gt 0 ]; do
        if ip link show "$interface" | grep -q "state UP"; then
            echo "WireGuard interface ($interface) is up!"
            return 0
        fi
        echo "WireGuard interface ($interface) not ready. Retrying in $wait_time seconds..."
        sleep $wait_time
        retries=$((retries - 1))
    done

    echo "Error: WireGuard interface ($interface) did not come up in time."
    exit 1
}

# Wait for WireGuard to initialize
wait_for_wireguard

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