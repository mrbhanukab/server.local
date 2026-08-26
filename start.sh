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
            # Get container name (compose prefixes project name)
            local project=$(docker compose -f "$compose_file" config --project-name 2>/dev/null)
            local container_name="${project}_${service}_1"
            
            # Check if container exists
            if docker inspect "$container_name" &>/dev/null; then
                local health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null)
                local running=$(docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null)
                
                if [ "$health" = "unhealthy" ]; then
                    log "Container $service is unhealthy!"
                    all_healthy=false
                    break
                elif [ "$health" = "healthy" ] || { [ "$health" = "<no value>" ] && [ "$running" = "true" ]; }; then
                    continue
                else
                    all_healthy=false
                    break
                fi
            else
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
    return 0
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
