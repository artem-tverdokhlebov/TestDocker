#!/usr/bin/env bash
set -ex

PROXY_IP=${PROXY_IP:-127.0.0.1}
PROXY_PORT=${PROXY_PORT:-12345}

DNS_SERVER=${DNS_SERVER:-1.1.1.1}
DNS_PORT=${DNS_PORT:-53}

LISTEN_ADDRESS=${LISTEN_ADDRESS:-127.0.0.1}

REDSOCKS_PORT=12345

DELAY=${DELAY:-1800}

echo "Delaying proxy start by ${DELAY} seconds..."
sleep "${DELAY}"

# Generate redsocks.conf dynamically
cat <<EOF > /etc/redsocks.conf
base {
  log_debug = off;
  log_info = off;
  log = "stderr";
  daemon = off;
  redirector = iptables;
}

redsocks {
  local_ip = 127.0.0.1;
  local_port = ${REDSOCKS_PORT};
  ip = ${PROXY_IP};
  port = ${PROXY_PORT};
  type = socks5;
  login = "${PROXY_USER}";
  password = "${PROXY_PASS}";
}
EOF

# Start redsocks in the background
redsocks -c /etc/redsocks.conf &
sleep 2

# Exclude traffic destined for the redsocks port itself
iptables -t nat -A OUTPUT -o lo -p tcp --dport ${REDSOCKS_PORT} -j RETURN

# Exclude traffic to the SOCKS proxy (to avoid infinite loop)
iptables -t nat -A OUTPUT -d ${PROXY_IP} -p tcp --dport ${PROXY_PORT} -j RETURN

# Exclude traffic to localhost:53 (DNS)
iptables -t nat -A OUTPUT -p udp -d 127.0.0.1 --dport 53 -j RETURN
iptables -t nat -A OUTPUT -p tcp -d 127.0.0.1 --dport 53 -j RETURN

# Exclude specific ports: 10022 (SSH) and 5900 (VNC)
iptables -t nat -A OUTPUT -p tcp --dport 10022 -j RETURN
iptables -t nat -A OUTPUT -p tcp --dport 5900 -j RETURN

# Redirect all other outbound TCP traffic to redsocks
iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port ${REDSOCKS_PORT}

# Filter Table Rules (for general packet filtering)

# Allow DNS requests to localhost:53
iptables -A OUTPUT -p udp -d 127.0.0.1 --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp -d 127.0.0.1 --dport 53 -j ACCEPT

# Allow DNS requests to 1.1.1.1 (proxied through redsocks)
iptables -A OUTPUT -p udp -d ${DNS_SERVER} --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp -d ${DNS_SERVER} --dport 53 -j ACCEPT

# Allow traffic on 10022 and 5900
iptables -A OUTPUT -p tcp --dport 10022 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 5900 -j ACCEPT

# Block WebRTC (STUN/TURN servers and dynamic UDP ports)

# Block STUN/TURN traffic (UDP ports 3478 and 3479)
iptables -A OUTPUT -p udp --dport 3478:3479 -j DROP

# Block dynamic UDP ports commonly used by WebRTC
iptables -A OUTPUT -p udp --dport 10000:65535 -j DROP

# Block multicast and broadcast traffic (commonly exploited for WebRTC)
iptables -A OUTPUT -p udp -d 224.0.0.0/4 -j DROP
iptables -A OUTPUT -p udp -d 255.255.255.255 -j DROP

# IPv6 Rules (Disable all IPv6 traffic)
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

# DNS

# DNSDIST CONFIGURATION
cat <<EOF > /etc/dnsdist.conf
setLocal("${LISTEN_ADDRESS}:${DNS_PORT}")

newServer({address="${DNS_SERVER}:${DNS_PORT}", tcpOnly=true})

-- Log queries (optional)
addAction(AllRule(), LogAction())
EOF

# Start dnsdist in the background
dnsdist --disable-syslog --supervised -C /etc/dnsdist.conf &
sleep 2

# Update resolv.conf to use dnsdist
cat <<EOF > /etc/resolv.conf
nameserver ${LISTEN_ADDRESS}
EOF

# Signal that redsocks is ready
echo "redsocks ready" > /tmp/redsocks_ready

exec tail -f /dev/null