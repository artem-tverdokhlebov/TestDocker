#!/usr/bin/env bash
set -ex

PROXY_IP=${PROXY_IP:-127.0.0.1}
PROXY_PORT=${PROXY_PORT:-12345}

DNS_SERVER=${DNS_SERVER:-8.8.8.8}
DNS_PORT=${DNS_PORT:-53}

LISTEN_ADDRESS=${LISTEN_ADDRESS:-127.0.0.1}

REDSOCKS_PORT=12345

DELAY=${DELAY:-1800}

echo "Delaying proxy start by ${DELAY} seconds..."
sleep "${DELAY}"

# Generate redsocks2.conf dynamically
cat <<EOF > /etc/redsocks2.conf
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

# Start redsocks2 in the background
redsocks2 -c /etc/redsocks2.conf &
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
echo "redsocks2 ready" > /tmp/redsocks_ready

exec tail -f /dev/null