# Docker Containers Auto-Start

Systemd service to ensure Docker containers start after a system reboot or power loss.

## Setup

### 1. Symlink the service file

```bash
sudo ln -s /home/dietpi/server.local/systemd/docker-containers-start.service \
           /etc/systemd/system/docker-containers-start.service
```

### 2. Enable the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable docker-containers-start.service
```

### 3. Start immediately (without rebooting)

```bash
sudo systemctl start docker-containers-start.service
```

## What it does

1. Starts **OpenNet** stack first (traefik, ddclient, crowdsec)
2. Waits 5 seconds
3. Starts **Jellyfin** stack (excluding `download` profile: gluetun, qbittorrent, prowlarr, bazarr)
4. Starts **metube**, **myspeed**, **dockge/dozzle**

## Managing download profile containers

To start containers with the `download` profile (VPN stack):

```bash
# Start jellyfin with download profile
docker compose -f /home/dietpi/server.local/jellyfin/docker-compose.yml --profile download up -d

# Or start specific containers
docker compose -f /home/dietpi/server.local/jellyfin/docker-compose.yml up -d gluetun qbittorrent prowlarr bazarr
```

## Troubleshooting

### Check service status
```bash
sudo systemctl status docker-containers-start.service
```

### View startup logs
```bash
sudo journalctl -u docker-containers-start.service
# or
cat /var/log/docker-startup.log
```

### Manual run
```bash
sudo /home/dietpi/server.local/systemd/start-containers.sh
```

### Disable auto-start
```bash
sudo systemctl disable docker-containers-start.service
```

## Files

- `docker-containers-start.service` - Systemd unit file
- `start-containers.sh` - Startup script
