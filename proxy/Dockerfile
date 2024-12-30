FROM debian:stable-slim

# Install dependencies and redsocks
RUN apt-get update && apt-get install -y --no-install-recommends \
    redsocks \
    iptables \
    ca-certificates \
    wget \
    tar \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Download and install dnscrypt-proxy manually
RUN wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.1.0/dnscrypt-proxy-linux_x86_64-2.1.0.tar.gz \
 && tar -xvzf dnscrypt-proxy-linux_x86_64-2.1.0.tar.gz \
 && mv linux-x86_64 /usr/local/dnscrypt-proxy \
 && cp /usr/local/dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/ \
 && chmod +x /usr/local/bin/dnscrypt-proxy \
 && rm dnscrypt-proxy-linux_x86_64-2.1.0.tar.gz

# Copy the start script into the container
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set the container's entry point
CMD ["/start.sh"]