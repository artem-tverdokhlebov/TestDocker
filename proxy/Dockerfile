FROM debian:stable-slim

RUN apt-get update && apt-get install -y procps && apt-get clean

RUN apt-get update && apt-get install -y --no-install-recommends redsocks iptables ca-certificates && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
