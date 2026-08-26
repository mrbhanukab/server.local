#!/bin/bash
# Docker containers startup script with health verification

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/docker-startup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

wait_for_healthy() {
    local compose_file=$1
    local timeout=${2:-120}
    local elapsed=0
    local interval=2

    log "Waiting for containers in $compose_file to be healthy..."

    while [ $elapsed -lt $timeout ]; do
        local all_healthy=true
        
        # Get all containers defined in this compose file
        local containers=$(docker compose -f "$compose_file" ps --format json 2>/dev/null | jq -r 'select(.Service != null) | .Service' 2>/dev/null | sort -u)
        
        if [ -z "$containers" ]; then
            # Fallback: get container names from docker-compose.yml
            containers=$(docker compose -f "$compose_file" config --services 2>/dev/null)
        fi
        
        for container in $containers; do
            local status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
            
            if [ "$status" = "unhealthy" ]; then
                log "Container $container is unhealthy!"
                all_healthy=false
                break
            elif [ "$status" = "no-healthcheck" ]; then
                # No healthcheck defined, just check if running
                local running=$(docker inspect --format='{{.State.Running}}' "$container" 2>/dev/null || echo "false")
                if [ "$running" != "true" ]; then
                    all_healthy=false
                    break
                fi
            elif [ "$status" != "healthy" ]; then
                all_healthy=false
                break
            fi
        done
        
        if [ "$all_healthy" = true ]; then
            log "All containers in $compose_file are healthy!"
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    log "Timeout waiting for containers in $compose_file"
    return 1
}

# Step 1: Stop all containers
log "Stopping all containers..."
docker compose -f "$BASE_DIR/opennet/docker-compose.yml" down 2>/dev/null || true
docker compose -f "$BASE_DIR/jellyfin/docker-compose.yml" down 2>/dev/null || true
docker compose -f "$BASE_DIR/metube/docker-compose.yml" down 2>/dev/null || true
docker compose -f "$BASE_DIR/myspeed/docker-compose.yml" down 2>/dev/null || true
docker compose -f "$BASE_DIR/docker/docker-compose.yml" down 2>/dev/null || true

log "All containers stopped."

# Step 2: Start dockge/dozzle first
log "Starting dockge & dozzle..."
docker compose -f "$BASE_DIR/docker/docker-compose.yml" up -d
wait_for_healthy "$BASE_DIR/docker/docker-compose.yml"

# Step 3: Start opennet
log "Starting opennet..."
docker compose -f "$BASE_DIR/opennet/docker-compose.yml" up -d
wait_for_healthy "$BASE_DIR/opennet/docker-compose.yml"

# Step 4: Start jellyfin
log "Starting jellyfin..."
docker compose -f "$BASE_DIR/jellyfin/docker-compose.yml" up -d

# Step 5: Start metube and myspeed
log "Starting metube and myspeed..."
docker compose -f "$BASE_DIR/metube/docker-compose.yml" up -d
docker compose -f "$BASE_DIR/myspeed/docker-compose.yml" up -d

log "Startup complete!"
