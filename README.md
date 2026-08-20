# Server.local

Docker stacks for media server, monitoring, and VPN services.

## Prerequisites

- Docker & Docker Compose
- Tailscale CLI (for remote access)
- Clone this repo to your server (e.g., `/home/dietpi/server.local`)

## Environment Setup

All services use environment variables for network bindings. Copy and configure the env file:

```bash
cp common.env.cp common.env
```

Edit `common.env` and set your IPs:

```env
LAN_IP=<your-lan-ip>        # e.g., 192.168.1.100
TAILSCALE_IP=<tailscale-ip> # e.g., 100.x.x.x
```

Find your Tailscale IP with: `tailscale ip -4`

## Starting Services

### Full Media Stack (Jellyfin, Radarr, Bazarr, Prowlarr, qBittorrent)

```bash
cd jellyfin
docker compose up -d
docker compose --profile download up -d   # Includes VPN services (qBittorrent, Prowlarr)
```

### Traefik Reverse Proxy + CrowdSec + DDNS

```bash
cd opennet
docker compose up -d
```

### Monitoring (Dockge + Dozzle)

```bash
cd docker
docker compose up -d
```

### MeTube Downloader

```bash
cd metube
docker compose up -d
```

### MySpeed (Speed Test Logs)

```bash
cd myspeed
docker compose up -d
```

## Tailscale Services Router

### Step 1: Enable Service Hosting

1. Go to [Tailscale admin console](https://login.tailscale.com/admin/machines)
2. Find your server device → Click **Edit**
3. Under **Service hosting**, add your service tags (e.g., `tag:dozzle`, `tag:dockge`, `tag:metube`, `tag:localspeed`)
4. Save changes

### Step 2: Run the Router

```bash
./tailscale-services.sh
```

### Step 3: Approve in Dashboard

1. Go to [Tailscale admin console](https://login.tailscale.com/admin/services)
2. Find the pending service approvals
3. Approve each service

### Verify

```bash
tailscale serve status
```

### Service Ports

| Service    | Local Port | Remote Port | URL                        |
|------------|------------|-------------|----------------------------|
| Dockge     | 5001       | 443         | https://dockge.mrbhanuka.dev |
| Dozzle     | 8084       | 443         | https://dozzle.mrbhanuka.dev |
| MeTube     | 8081       | 443         | https://metube.mrbhanuka.dev |
| MySpeed    | 5216       | 443         | https://myspeed.mrbhanuka.dev |
| Jellyfin   | 8096       | via Traefik | https://jellyfin.mrbhanuka.dev |
| Jellyseerr | 5055       | via Traefik | https://jellyseerr.mrbhanuka.dev |
| Radarr     | 7878       | LAN only    |                            |
| Bazarr     | 6767       | LAN only    |                            |
| qBittorrent| 8080       | VPN only    |                            |
| Prowlarr   | 9696       | VPN only    |                            |

## Volume Permissions

Media directories require correct ownership:

```bash
sudo chown -R 1000:1000 /mnt/data/media
```

## TLS/SSL Certificates

### Cloudflare Origin Certificate (for Traefik)

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com) → your domain → **SSL/TLS** → **Origin Server**
2. Click **Create Certificate**
3. Leave defaults (RSA 2048, 15 years) → Click **Create**
4. Copy the **Certificate** and **Private Key**

### Install Certificates

```bash
# Create certs directory
mkdir -p opennet/certs

# Save certificate
cat > opennet/certs/cloudflare-origin.crt << 'EOF'
-----BEGIN CERTIFICATE-----
<paste certificate here>
-----END CERTIFICATE-----
EOF

# Save private key
cat > opennet/certs/cloudflare-origin.key << 'EOF'
-----BEGIN PRIVATE KEY-----
<paste private key here>
-----END PRIVATE KEY-----
EOF
```

## Updating Stacks

```bash
cd <stack-directory>
docker compose pull
docker compose up -d
```
