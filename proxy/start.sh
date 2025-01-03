#!/usr/bin/env bash
set -ex

PROXY_IP=${PROXY_IP:-127.0.0.1}
PROXY_PORT=${PROXY_PORT:-12345}

DNS_SERVER=${DNS_SERVER:-1.1.1.1}
DNS_PORT=${DNS_PORT:-53}

LISTEN_ADDRESS=${LISTEN_ADDRESS:-127.0.0.1}

# Delay proxy start by 30 minutes (1800 seconds)
echo "Delaying proxy start by 30 minutes..."
sleep 1800

# Generate redsocks.conf dynamically
cat <<EOF > /etc/redsocks.conf
base {
  log_debug = on;
  log_info = on;
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

redudp {
  local_ip = 127.0.0.1;
  local_port = 10053;

  ip = ${PROXY_IP};
  port = ${PROXY_PORT};
  login = "${PROXY_USER}";
  password = "${PROXY_PASS}";

  dest_ip = ${DNS_SERVER};
  dest_port = ${DNS_PORT};

  udp_timeout = 30;
  udp_timeout_stream = 180;
}
EOF

# Start redsocks in the background
redsocks -c /etc/redsocks.conf &
sleep 2

# Exclude traffic destined for the redsocks port (12345 and 10053)
iptables -t nat -A OUTPUT -o lo -p tcp --dport 12345 -j RETURN
iptables -t nat -A OUTPUT -o lo -p udp --dport 10053 -j RETURN

# Exclude traffic to the external SOCKS proxy (prevent looping)
iptables -t nat -A OUTPUT -d ${PROXY_IP} -p tcp --dport ${PROXY_PORT} -j RETURN
iptables -t nat -A OUTPUT -d ${PROXY_IP} -p udp --dport ${PROXY_PORT} -j RETURN

# Exclude loopback traffic in general
iptables -t nat -A OUTPUT -o lo -j RETURN

# Exclude traffic for SSH (port 50922) and VNC (port 5999)
iptables -t nat -A OUTPUT -p tcp --dport 10022 -j RETURN  # Internal SSH port
iptables -t nat -A OUTPUT -p tcp --dport 5900 -j RETURN   # Internal VNC port

# Redirect all other outbound TCP traffic to redsocks
iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port 12345

# Configure iptables to redirect DNS traffic
iptables -t nat -A OUTPUT -o lo -p udp --dport 53 -j RETURN
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-port 10053

# DNS

# Create dnsmasq configuration
cat <<EOF > /etc/dnsmasq.conf
no-resolv
server=${LISTEN_ADDRESS}#10053
listen-address=${LISTEN_ADDRESS}
EOF

# Update resolv.conf to use dnsmasq
cat <<EOF > /etc/resolv.conf
nameserver ${LISTEN_ADDRESS}
EOF

# Start dnsmasq in the background
dnsmasq -k &
sleep 2

# Signal that redsocks is ready
echo "redsocks ready" > /tmp/redsocks_ready

# Keep container alive
exec tail -f /dev/null