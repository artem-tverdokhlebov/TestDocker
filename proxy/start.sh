#!/usr/bin/env bash
set -ex

# Environment variable to toggle proxy bypass (default: no)
BYPASS_PROXY=${BYPASS_PROXY:-no}

if [[ "$BYPASS_PROXY" == "yes" ]]; then
  echo "Proxy bypass mode enabled. Traffic will not be redirected through the proxy."

  # Signal that the proxy setup is bypassed
  echo "proxy bypassed" > /tmp/redsocks_ready
else
  echo "Proxy mode enabled. Configuring redsocks and iptables..."

  # Start redsocks in the background
  redsocks -c /etc/redsocks.conf &
  sleep 2

  # Exclude traffic destined for the redsocks port (12345)
  iptables -t nat -A OUTPUT -o lo -p tcp --dport 12345 -j RETURN

  # Exclude traffic to the external SOCKS proxy (prevent looping)
  iptables -t nat -A OUTPUT -d 142.252.4.175 -p tcp --dport 62769 -j RETURN

  # Exclude loopback traffic in general
  iptables -t nat -A OUTPUT -o lo -j RETURN

  # Exclude traffic for SSH (port 50922) and VNC (port 5999)
  iptables -t nat -A OUTPUT -p tcp --dport 10022 -j RETURN  # Internal SSH port
  iptables -t nat -A OUTPUT -p tcp --dport 5900 -j RETURN   # Internal VNC port

  # Redirect all other outbound TCP traffic to redsocks
  iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port 12345

  # Signal that redsocks is ready
  echo "redsocks ready" > /tmp/redsocks_ready
fi

# Keep container alive
exec tail -f /dev/null