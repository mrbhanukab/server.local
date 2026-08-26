#!/bin/bash
# Docker containers startup script
# Used by docker-containers-start.service

set -e

LOG_FILE="/var/log/docker-startup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting Docker containers..."

# Base directory (where this script and compose files reside)
BASE_DIR="/home/dietpi/server.local"

# 1. OpenNet stack (first, needed for reverse proxy)
log "Starting OpenNet stack..."
docker compose -f "$BASE_DIR/opennet/docker-compose.yml" up -d

log "Waiting 5 seconds..."
sleep 5

# 2. Jellyfin stack (download profile excluded by default)
log "Starting Jellyfin stack..."
docker compose -f "$BASE_DIR/jellyfin/docker-compose.yml" up -d

# 3. Other stacks
log "Starting metube..."
docker compose -f "$BASE_DIR/metube/docker-compose.yml" up -d

log "Starting myspeed..."
docker compose -f "$BASE_DIR/myspeed/docker-compose.yml" up -d

log "Starting dockge & dozzle..."
docker compose -f "$BASE_DIR/docker/docker-compose.yml" up -d

log "Docker containers startup complete."
