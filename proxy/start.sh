#!/usr/bin/env bash
set -ex

modprobe nf_log_ipv4
echo "nf_log_ipv4" >> /etc/modules

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
iptables -t nat -A OUTPUT -p tcp --dport 10022 -j RETURN  # Internal SSH port
iptables -t nat -A OUTPUT -p tcp --dport 5900 -j RETURN   # Internal VNC port

# Redirect all other outbound TCP traffic to redsocks
iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port 12345

# Block and log UDP traffic
iptables -A OUTPUT -p udp -j NFLOG --nflog-prefix "BLOCKED UDP: " --nflog-group 0
iptables -A OUTPUT -p udp -j DROP

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

# Start a background process to stream kernel logs
(while true; do dmesg --follow | grep --line-buffered "BLOCKED UDP"; done) &

# Keep container alive
exec tail -f /dev/null