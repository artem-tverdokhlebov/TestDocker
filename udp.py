import sys
import socks
import socket
import struct
import argparse

def resolve_domain_via_proxy(proxy_host, proxy_port, username, password, domain):
    try:
        # Set up the SOCKS5 proxy
        sock = socks.socksocket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.set_proxy(socks.SOCKS5, proxy_host, int(proxy_port), username=username, password=password)

        # Google DNS server address and port
        dns_server = ("8.8.8.8", 53)

        # Construct a simple DNS query for the domain
        query_id = b"\x01\x00"  # Query ID
        flags = b"\x01\x00"  # Standard query
        q_count = b"\x00\x01"  # One question
        answer_rrs = b"\x00\x00"
        authority_rrs = b"\x00\x00"
        additional_rrs = b"\x00\x00"

        # Format the domain name into DNS query format
        domain_parts = domain.split(".")
        domain_query = b"".join(bytes([len(part)]) + part.encode() for part in domain_parts) + b"\x00"
        query_type = b"\x00\x01"  # A record (IPv4)
        query_class = b"\x00\x01"  # IN class

        # Full DNS query
        dns_query = query_id + flags + q_count + answer_rrs + authority_rrs + additional_rrs + domain_query + query_type + query_class

        # Send DNS query via proxy
        sock.connect(dns_server)
        sock.send(dns_query)

        # Receive and parse DNS response
        response = sock.recv(512)
        if response:
            print("DNS query sent successfully.")
            ip_start = response.find(domain_query) + len(domain_query) + 4
            ip_address = struct.unpack(">4B", response[ip_start:ip_start + 4])
            print(f"{domain} resolved to {'.'.join(map(str, ip_address))}")
        else:
            print("No response received from DNS server.")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        sock.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Resolve a domain via a SOCKS5 proxy.")
    parser.add_argument("--proxy-host", required=True, help="SOCKS5 proxy host")
    parser.add_argument("--proxy-port", required=True, help="SOCKS5 proxy port")
    parser.add_argument("--username", required=True, help="SOCKS5 proxy username")
    parser.add_argument("--password", required=True, help="SOCKS5 proxy password")
    parser.add_argument("--domain", required=True, help="Domain to resolve (e.g., example.com)")

    args = parser.parse_args()

    resolve_domain_via_proxy(
        proxy_host=args.proxy_host,
        proxy_port=args.proxy_port,
        username=args.username,
        password=args.password,
        domain=args.domain
    )