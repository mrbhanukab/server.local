#!/bin/bash
# Docker containers startup script with health verification

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/docker-startup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

wait_for_healthy() {
    local compose_file=$1
    local timeout=${2:-120}
    local elapsed=0
    local interval=2

    log "Waiting for containers in $compose_file to be healthy..."

    # Get all service names from compose file
    local services=$(docker compose -f "$compose_file" config --services 2>/dev/null)
    
    if [ -z "$services" ]; then
        log "Warning: Could not get services from $compose_file"
        return 0
    fi

    while [ $elapsed -lt $timeout ]; do
        local all_healthy=true
        
        for service in $services; do
            # Check if container exists - try short name first, then with suffix
            local running="false"
            local health="none"
            
            if docker inspect "$service" &>/dev/null; then
                running=$(docker inspect --format='{{.State.Running}}' "$service" 2>/dev/null)
                health=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null || echo "none")
            elif docker inspect "${service}-1" &>/dev/null; then
                running=$(docker inspect --format='{{.State.Running}}' "${service}-1" 2>/dev/null)
                health=$(docker inspect --format='{{.State.Health.Status}}' "${service}-1" 2>/dev/null || echo "none")
            fi
            
            # Log status
            log "  $service: running=$running health=$health"
            
            if [ "$running" != "true" ]; then
                all_healthy=false
                continue
            fi
            
            # Healthy or no healthcheck (empty/none) = good
            if [ "$health" = "healthy" ] || [ "$health" = "none" ] || [ -z "$health" ]; then
                continue
            fi
            
            # starting or <nil> = still starting, wait
            all_healthy=false
        done
        
        if [ "$all_healthy" = true ]; then
            log "All containers in $compose_file are healthy!"
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    log "Timeout waiting for containers in $compose_file"
    return 0
}

# Step 1: Stop all containers
log "Stopping all containers..."
docker compose -f "$BASE_DIR/opennet/docker-compose.yml" down 2>/dev/null &
docker compose -f "$BASE_DIR/jellyfin/docker-compose.yml" down 2>/dev/null &
docker compose -f "$BASE_DIR/metube/docker-compose.yml" down 2>/dev/null &
docker compose -f "$BASE_DIR/myspeed/docker-compose.yml" down 2>/dev/null &
docker compose -f "$BASE_DIR/docker/docker-compose.yml" down 2>/dev/null &
wait

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
