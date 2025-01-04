FROM debian:stable-slim

RUN apt-get update && apt-get install -y kmod iproute2

RUN apt-get update && apt-get install -y --no-install-recommends redsocks iptables dnsdist ca-certificates && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
