FROM debian:bookworm-slim

# Install dependencies and cloudflare-warp
RUN apt-get update -qq && \
    apt-get install -y -qq curl gnupg ca-certificates iperf3 iproute2 iptables && \
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(. /etc/os-release && echo "$VERSION_CODENAME") main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
    apt-get update -qq && \
    apt-get install -y -qq cloudflare-warp && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
