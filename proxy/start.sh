#!/usr/bin/env bash
set -ex

# Configuration variables
PROXY_IP=${PROXY_IP:-127.0.0.1}         # Upstream SOCKS5 proxy IP
PROXY_PORT=${PROXY_PORT:-1080}          # Upstream SOCKS5 proxy port
PROXY_USER=${PROXY_USER:-""}            # SOCKS5 username (if required)
PROXY_PASS=${PROXY_PASS:-""}            # SOCKS5 password (if required)
GOST_PORT=${GOST_PORT:-12345}           # Local transparent proxy port
DELAY=${DELAY:-1800}

echo "Delaying proxy start by ${DELAY} seconds..."
sleep "${DELAY}"

# Start GOST in transparent mode
gost -L "red://:${GOST_PORT}" \
     -F "socks5://${PROXY_USER}:${PROXY_PASS}@${PROXY_IP}:${PROXY_PORT}" &

# Exclude traffic to the SOCKS5 proxy from redirection
iptables -t nat -A OUTPUT -p tcp -d ${PROXY_IP} --dport ${PROXY_PORT} -j RETURN

# Exclude specific ports (10022 and 5900) from redirection
iptables -t nat -A OUTPUT -p tcp --dport 10022 -j RETURN
iptables -t nat -A OUTPUT -p tcp --dport 5900 -j RETURN

# Block UDP requests to Google's DNS servers (8.8.8.8 and 8.8.4.4)
iptables -A OUTPUT -p udp -d 8.8.8.8 --dport 53 -j DROP
iptables -A OUTPUT -p udp -d 8.8.4.4 --dport 53 -j DROP

# Redirect all other TCP traffic to GOST
iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port ${GOST_PORT}

# Update /etc/resolv.conf to use the tunnel IP for DNS resolution
cat <<EOF > /etc/resolv.conf
options use-vc
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# Signal that GOST is ready
echo "gost ready" > /tmp/gost_ready

# Keep the container running
exec tail -f /dev/null