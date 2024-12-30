#!/usr/bin/env bash
set -ex

PROXY_IP=${PROXY_IP:-127.0.0.1}
PROXY_PORT=${PROXY_PORT:-12345}

# Signal that redsocks is ready
echo "redsocks ready" > /tmp/redsocks_ready

# Delay proxy start by 30 minutes (1800 seconds)
echo "Delaying proxy start by 30 minutes..."
sleep 120

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

# Redirect UDP DNS (port 53) traffic to Redsocks
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 10053

# Redirect TCP DNS (port 53) traffic (rare, but for completeness)
iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 10053

# Keep container alive
exec tail -f /dev/null