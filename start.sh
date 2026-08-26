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

    local services=$(docker compose -f "$compose_file" config --services 2>/dev/null)
    
    if [ -z "$services" ]; then
        log "Warning: Could not get services from $compose_file"
        return 0
    fi

    log "Checking health for: $(echo $services | tr '\n' ' ')"

    while true; do
        local elapsed=$(($(date +%s) - start_time))
        
        if [ $elapsed -ge $timeout ]; then
            log "TIMEOUT after ${timeout}s"
            return 1
        fi

        local all_healthy=true
        local all_running=true
        local check_health=""
        
        for service in $services; do
            local running="false"
            local health="none"
            local found="no"
            
            # Try direct name
            if docker inspect "$service" &>/dev/null; then
                found="yes"
                running=$(docker inspect --format='{{.State.Running}}' "$service" 2>/dev/null)
                health=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null)
                [ -z "$health" ] && health="none"
            # Try with -1 suffix
            elif docker inspect "${service}-1" &>/dev/null; then
                found="yes"
                running=$(docker inspect --format='{{.State.Running}}' "${service}-1" 2>/dev/null)
                health=$(docker inspect --format='{{.State.Health.Status}}' "${service}-1" 2>/dev/null)
                [ -z "$health" ] && health="none"
            fi
            
            check_health="$check_health $service[$running/$health]"
            
            if [ "$found" = "no" ]; then
                all_running=false
                all_healthy=false
                continue
            fi
            
            if [ "$running" != "true" ]; then
                all_running=false
                all_healthy=false
                continue
            fi
            
            if [ "$health" = "healthy" ]; then
                continue
            elif [ "$health" = "none" ]; then
                if [ $elapsed -ge 20 ]; then
                    continue
                fi
            fi
            
            all_healthy=false
        done
        
        log "  [$elapsed s] $check_health"
        
        if [ "$all_healthy" = true ]; then
            log "All healthy"
            return 0
        fi
        
        if [ "$all_running" != "true" ]; then
            log "Some containers not running"
            return 1
        fi
        
        sleep 2
    done
}

cleanup

log "Starting dockge & dozzle..."
docker compose -f "$BASE_DIR/docker/docker-compose.yml" up -d
if ! wait_for_healthy "$BASE_DIR/docker/docker-compose.yml"; then
    log "dockge/dozzle FAILED"
    cleanup
    exit 1
fi

log "Starting opennet..."
docker compose -f "$BASE_DIR/opennet/docker-compose.yml" up -d
if ! wait_for_healthy "$BASE_DIR/opennet/docker-compose.yml"; then
    log "opennet FAILED"
    cleanup
    exit 1
fi

log "Starting jellyfin..."
docker compose -f "$BASE_DIR/jellyfin/docker-compose.yml" up -d

log "Starting metube & myspeed..."
docker compose -f "$BASE_DIR/metube/docker-compose.yml" up -d
docker compose -f "$BASE_DIR/myspeed/docker-compose.yml" up -d

log "Done!"
