#!/usr/bin/env bash
set -ex

PROXY_IP=${PROXY_IP:-127.0.0.1}
PROXY_PORT=${PROXY_PORT:-12345}

DNS_SERVER=${DNS_SERVER:-1.1.1.1}
DNS_PORT=${DNS_PORT:-53}

LISTEN_ADDRESS=${LISTEN_ADDRESS:-127.0.0.1}

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
  local_port = 12345;
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

# Exclude traffic destined for the redsocks port (12345)
iptables -t nat -A OUTPUT -o lo -p tcp --dport 12345 -j RETURN

# Exclude traffic to the external SOCKS proxy (prevent looping)
iptables -t nat -A OUTPUT -d ${PROXY_IP} -p tcp --dport ${PROXY_PORT} -j RETURN

# Exclude loopback traffic in general
iptables -t nat -A OUTPUT -o lo -j RETURN

# Exclude traffic for SSH (port 50922) and VNC (port 5999)
iptables -t nat -A OUTPUT -p tcp --dport 10022 -j RETURN
iptables -t nat -A OUTPUT -p tcp --dport 5900 -j RETURN

# Redirect all other outbound TCP traffic to redsocks
iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port 12345

# Allow DNS traffic (UDP port 53)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

# Allow multicast DNS (mDNS) traffic (UDP port 5353)
iptables -A OUTPUT -p udp --dport 5353 -j ACCEPT

# Allow multicast traffic (224.0.0.0/4)
iptables -A OUTPUT -p udp -d 224.0.0.0/4 -j ACCEPT

# Allow traffic to loopback
iptables -A OUTPUT -p udp -d 127.0.0.0/8 -j ACCEPT

# Block STUN/TURN servers (common internet UDP services)
iptables -A OUTPUT -p udp --dport 3478:3479 -j DROP

# Block all other UDP traffic to the internet (dynamic port range and beyond)
iptables -A OUTPUT -p udp -d 0.0.0.0/0 --dport 1024:65535 -j DROP

# Drop all IPv6 traffic
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