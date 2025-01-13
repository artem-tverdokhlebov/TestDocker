#!/usr/bin/env bash
set -ex

# Configuration variables
PROXY_IP=${PROXY_IP:-127.0.0.1}
PROXY_PORT=${PROXY_PORT:-12345}

DNS_SERVER=${DNS_SERVER:-8.8.8.8}
DNS_PORT=${DNS_PORT:-53}

LISTEN_ADDRESS=${LISTEN_ADDRESS:-127.0.0.1}

GOST_PORT=${GOST_PORT:-12345}
DELAY=${DELAY:-1800}

echo "Delaying proxy start by ${DELAY} seconds..."
sleep "${DELAY}"

# Start gost for SOCKS5 proxying and DNS UDP-to-TCP forwarding
# Proxy TCP traffic
gost -L "tcp://${LISTEN_ADDRESS}:${GOST_PORT}" -F "socks5://${PROXY_IP}:${PROXY_PORT}" &
# Proxy DNS traffic over TCP
gost -L "udp://${LISTEN_ADDRESS}:${DNS_PORT}" -F "tcp://${DNS_SERVER}:${DNS_PORT}" &
sleep 2

# Exclude traffic destined for the gost port itself
iptables -t nat -A OUTPUT -o lo -p tcp --dport ${GOST_PORT} -j RETURN

# Exclude traffic to the SOCKS proxy (to avoid infinite loop)
iptables -t nat -A OUTPUT -d ${PROXY_IP} -p tcp --dport ${PROXY_PORT} -j RETURN

# Exclude traffic to localhost:53 (DNS)
iptables -t nat -A OUTPUT -p udp -d 127.0.0.1 --dport 53 -j RETURN
iptables -t nat -A OUTPUT -p tcp -d 127.0.0.1 --dport 53 -j RETURN

# Exclude specific ports: 10022 (SSH) and 5900 (VNC)
iptables -t nat -A OUTPUT -p tcp --dport 10022 -j RETURN
iptables -t nat -A OUTPUT -p tcp --dport 5900 -j RETURN

# Redirect all other outbound TCP traffic to gost
iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port ${GOST_PORT}

# Redirect all DNS (UDP 53) traffic to gost's UDP listener
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-port ${DNS_PORT}

# IPv6 Rules (Disable all IPv6 traffic)
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

# Update resolv.conf to use gost for DNS
cat <<EOF > /etc/resolv.conf
nameserver ${LISTEN_ADDRESS}
EOF

# Signal that gost is ready
echo "gost ready" > /tmp/gost_ready

exec tail -f /dev/null