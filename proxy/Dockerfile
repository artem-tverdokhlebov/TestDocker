# Use a lightweight base image
FROM debian:stable-slim

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget iptables ca-certificates iproute2 dnsutils net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install gost
RUN wget https://github.com/go-gost/gost/releases/download/v3.0.0/gost_3.0.0_linux_amd64.tar.gz -O /tmp/gost.tar.gz && \
    tar -xzf /tmp/gost.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/gost && \
    rm -rf /tmp/gost.tar.gz

# Copy the start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set the entry point
CMD ["/start.sh"]