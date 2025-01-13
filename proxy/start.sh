#!/usr/bin/env bash
set -ex

# Configuration variables
PROXY_IP=${PROXY_IP:-127.0.0.1}         # Upstream SOCKS5 proxy IP
PROXY_PORT=${PROXY_PORT:-1080}          # Upstream SOCKS5 proxy port
PROXY_USER=${PROXY_USER:-""}            # SOCKS5 username (if required)
PROXY_PASS=${PROXY_PASS:-""}            # SOCKS5 password (if required)
GOST_PORT=${GOST_PORT:-12345}           # Local transparent proxy port for TCP traffic
GOST_DNS_PORT=10053                     # GOST DNS proxy port
DNS_PORT=53                             # Local dnsdist UDP listener port
UPSTREAM_DNS="8.8.8.8"                  # Upstream DNS server for GOST
DELAY=${DELAY:-1800}                    # Startup delay (default: 1800 seconds)

echo "Delaying proxy start by ${DELAY} seconds..."
sleep "${DELAY}"

# Start GOST for DNS TCP tunneling
gost -L "dns+tcp://127.0.0.1:${GOST_DNS_PORT}/${UPSTREAM_DNS}:${DNS_PORT}?mode=tcp" \
     -F "socks5://${PROXY_USER}:${PROXY_PASS}@${PROXY_IP}:${PROXY_PORT}" &

# Start GOST in transparent mode for general TCP traffic
gost -L "red://:${GOST_PORT}" \
     -F "socks5://${PROXY_USER}:${PROXY_PASS}@${PROXY_IP}:${PROXY_PORT}" &

# Start dnsdist to handle DNS queries over UDP and forward them to GOST
cat <<EOF > /etc/dnsdist.conf
setLocal("127.0.0.1:${DNS_PORT}")
newServer({address="127.0.0.1:${GOST_DNS_PORT}", tcpOnly=true})
EOF

dnsdist --supervised --disable-syslog --config /etc/dnsdist.conf &

# Exclude traffic to the SOCKS5 proxy from redirection
iptables -t nat -A OUTPUT -p tcp -d ${PROXY_IP} --dport ${PROXY_PORT} -j RETURN

# Exclude all traffic to 127.0.0.1
iptables -t nat -A OUTPUT -d 127.0.0.1 -j RETURN

# Exclude all traffic to UPSTREAM_DNS
iptables -t nat -A OUTPUT -d ${UPSTREAM_DNS} -j RETURN

# Exclude specific ports (10022 and 5900) from redirection
iptables -t nat -A OUTPUT -p tcp --dport 10022 -j RETURN
iptables -t nat -A OUTPUT -p tcp --dport 5900 -j RETURN

# Redirect all other TCP traffic to GOST
iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port ${GOST_PORT}

# Update /etc/resolv.conf to use dnsdist for DNS resolution
cat <<EOF > /etc/resolv.conf
nameserver 127.0.0.1
EOF

# Signal that the system is ready
echo "proxy ready" > /tmp/proxy_ready

# Keep the container running
exec tail -f /dev/null