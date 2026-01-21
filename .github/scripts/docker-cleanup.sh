#!/usr/bin/env bash
#
# docker-cleanup.sh - Aggressive Docker cleanup for CI/CD environments
#
# This script performs thorough cleanup of Docker resources to prevent
# GitHub Actions runners from running out of disk space.
#
# Usage: ./docker-cleanup.sh [--full|--service <compose-file>]
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get current disk usage
get_disk_usage() {
    df / | tail -1 | awk '{print $4}'
}

# Log disk space
log_disk_space() {
    local label="${1:-Current}"
    local available=$(get_disk_usage)
    log_info "$label disk space available: ${available}K"
}

# Cleanup specific service
cleanup_service() {
    local compose_file="$1"
    
    if [[ ! -f "$compose_file" ]]; then
        log_error "Compose file not found: $compose_file"
        return 1
    fi
    
    local service_dir=$(dirname "$compose_file")
    local service_name=$(basename "$service_dir")
    
    log_info "Cleaning up service: $service_name"
    
    # Stop and remove containers
    docker compose -f "$compose_file" down --volumes --remove-orphans 2>/dev/null || true
    
    # Get images used by this service and remove them
    local images=$(docker compose -f "$compose_file" config 2>/dev/null | \
                   grep -E '^\s*image:' | \
                   sed 's/.*image:\s*//' | \
                   tr -d '"' || true)
    
    for img in $images; do
        log_info "Removing image: $img"
        docker rmi "$img" 2>/dev/null || true
    done
    
    # Remove any dangling resources
    docker container prune -f 2>/dev/null || true
    docker volume prune -f 2>/dev/null || true
    docker network prune -f 2>/dev/null || true
    docker image prune -f 2>/dev/null || true
}

# Full system cleanup
cleanup_full() {
    log_info "Performing full Docker cleanup..."
    
    local before=$(get_disk_usage)
    
    # Stop all containers
    log_info "Stopping all containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    
    # Remove all containers
    log_info "Removing all containers..."
    docker rm -f $(docker ps -aq) 2>/dev/null || true
    
    # Remove all volumes
    log_info "Removing all volumes..."
    docker volume rm -f $(docker volume ls -q) 2>/dev/null || true
    
    # Remove all networks (except default ones)
    log_info "Removing custom networks..."
    docker network rm $(docker network ls -q --filter "type=custom") 2>/dev/null || true
    
    # Remove all images
    log_info "Removing all images..."
    docker rmi -f $(docker images -aq) 2>/dev/null || true
    
    # System prune (aggressive)
    log_info "Running system prune..."
    docker system prune -af --volumes 2>/dev/null || true
    
    # Remove build cache
    log_info "Clearing build cache..."
    docker builder prune -af 2>/dev/null || true
    
    local after=$(get_disk_usage)
    local freed=$((after - before))
    
    log_info "Cleanup complete. Freed: ${freed}K"
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --full              Perform full system cleanup (removes ALL Docker resources)
    --service <file>    Cleanup specific service by compose file path
    --help              Show this help message

Examples:
    $0 --full
    $0 --service services/metabase/docker-compose.yml

EOF
}

# Main
main() {
    log_disk_space "Initial"
    
    case "${1:-}" in
        --full)
            cleanup_full
            ;;
        --service)
            if [[ -z "${2:-}" ]]; then
                log_error "Missing compose file argument"
                usage
                exit 1
            fi
            cleanup_service "$2"
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            # Default: light cleanup
            log_info "Performing light cleanup (dangling resources only)..."
            docker system prune -f 2>/dev/null || true
            ;;
    esac
    
    log_disk_space "Final"
}

main "$@"
