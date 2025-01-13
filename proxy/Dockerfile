# Use a lightweight base image
FROM debian:stable-slim

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget iptables ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install gost v2.12.0
RUN wget https://github.com/ginuerzh/gost/releases/download/v2.12.0/gost_2.12.0_linux_amd64.tar.gz -O /tmp/gost.tar.gz && \
    tar -xzf /tmp/gost.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/gost && \
    rm -rf /tmp/gost.tar.gz

# Copy the start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set the entry point
CMD ["/start.sh"]