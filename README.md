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

Expose local services via Tailscale Funnel for remote access:

```bash
# Set your LAN IP in the script
# Edit tailscale-services.sh and replace [IP_ADDRESS] with your actual LAN IP

# Run the router
./tailscale-services.sh

# Check status
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

## Updating Stacks

```bash
cd <stack-directory>
docker compose pull
docker compose up -d
```
