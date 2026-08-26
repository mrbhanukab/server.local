#!/bin/bash
# Docker containers startup script with health verification

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/docker-startup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

cleanup() {
    log "Stopping all containers..."
    docker compose -f "$BASE_DIR/opennet/docker-compose.yml" down 2>/dev/null &
    docker compose -f "$BASE_DIR/jellyfin/docker-compose.yml" down 2>/dev/null &
    docker compose -f "$BASE_DIR/metube/docker-compose.yml" down 2>/dev/null &
    docker compose -f "$BASE_DIR/myspeed/docker-compose.yml" down 2>/dev/null &
    docker compose -f "$BASE_DIR/docker/docker-compose.yml" down 2>/dev/null &
    wait
}

wait_for_healthy() {
    local compose_file=$1
    local timeout=${2:-120}
    local start_time=$(date +%s)

    # Get all service names from compose file
    local services=$(docker compose -f "$compose_file" config --services 2>/dev/null)
    
    if [ -z "$services" ]; then
        log "Warning: Could not get services from $compose_file"
        return 0
    fi

    while true; do
        local elapsed=$(($(date +%s) - start_time))
        
        if [ $elapsed -ge $timeout ]; then
            log "TIMEOUT"
            return 1
        fi

        local all_healthy=true
        local all_running=true
        
        for service in $services; do
            local running="false"
            local health="none"
            
            if docker inspect "$service" &>/dev/null; then
                running=$(docker inspect --format='{{.State.Running}}' "$service" 2>/dev/null)
                health=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null || echo "none")
            elif docker inspect "${service}-1" &>/dev/null; then
                running=$(docker inspect --format='{{.State.Running}}' "${service}-1" 2>/dev/null)
                health=$(docker inspect --format='{{.State.Health.Status}}' "${service}-1" 2>/dev/null || echo "none")
            else
                running="false"
            fi
            
            if [ "$running" != "true" ]; then
                all_running=false
                all_healthy=false
                continue
            fi
            
            if [ "$health" = "healthy" ]; then
                continue
            elif [ "$health" = "none" ] || [ -z "$health" ]; then
                # No healthcheck: healthy if running > 10 seconds
                if [ $elapsed -ge 10 ]; then
                    continue
                fi
            fi
            
            all_healthy=false
        done
        
        if [ "$all_healthy" = true ]; then
            return 0
        fi
        
        if [ "$all_running" != "true" ]; then
            return 1
        fi
        
        sleep 2
    done
}

# Step 1: Stop all containers
cleanup

# Step 2: Start dockge/dozzle first
log "Starting dockge & dozzle..."
docker compose -f "$BASE_DIR/docker/docker-compose.yml" up -d
if ! wait_for_healthy "$BASE_DIR/docker/docker-compose.yml"; then
    log "FAILED"
    cleanup
    exit 1
fi

# Step 3: Start opennet
log "Starting opennet..."
docker compose -f "$BASE_DIR/opennet/docker-compose.yml" up -d
if ! wait_for_healthy "$BASE_DIR/opennet/docker-compose.yml"; then
    log "FAILED"
    cleanup
    exit 1
fi

# Step 4: Start jellyfin
log "Starting jellyfin..."
docker compose -f "$BASE_DIR/jellyfin/docker-compose.yml" up -d

# Step 5: Start metube and myspeed
log "Starting metube and myspeed..."
docker compose -f "$BASE_DIR/metube/docker-compose.yml" up -d
docker compose -f "$BASE_DIR/myspeed/docker-compose.yml" up -d

log "Done!"
