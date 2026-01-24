#!/usr/bin/env bash
#
# test-service.sh - Test a single Docker Compose service
#
# This script tests a single service by starting it, running health checks,
# and then cleaning up. It provides detailed output for CI/CD pipelines.
#
# Usage: ./test-service.sh <service-name> [--no-cleanup]
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Timeouts (in seconds)
PULL_TIMEOUT=${PULL_TIMEOUT:-300}
START_TIMEOUT=${START_TIMEOUT:-120}
HEALTH_TIMEOUT=${HEALTH_TIMEOUT:-180}
HEALTH_INTERVAL=${HEALTH_INTERVAL:-10}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Get service directory
get_service_dir() {
    local service="$1"
    echo "$REPO_ROOT/services/$service"
}

# Load environment for service
load_service_env() {
    local service_dir="$1"
    
    # Disable nounset (-u) temporarily as env files may contain $ characters
    # in values that look like unset variables (e.g., bcrypt hashes like $2y$10$...)
    set +u
    
    # Load .env (versions)
    if [[ -f "$service_dir/.env" ]]; then
        set -a
        source "$service_dir/.env" 2>/dev/null || true
        set +a
    fi
    
    # Load .env.example (fallback for secrets)
    if [[ -f "$service_dir/.env.example" ]]; then
        set -a
        source "$service_dir/.env.example" 2>/dev/null || true
        set +a
    fi
    
    set -u
    
    # Override domain for testing
    export SERVICE_DOMAIN="${SERVICE:-unknown}_test.local"
}

# Check if containers are healthy
check_container_health() {
    local compose_file="$1"
    local max_attempts=$((HEALTH_TIMEOUT / HEALTH_INTERVAL))
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Health check attempt $attempt/$max_attempts"
        
        # Count running containers
        local total=$(docker compose -f "$compose_file" ps -q 2>/dev/null | wc -l)
        local running=$(docker compose -f "$compose_file" ps --status running -q 2>/dev/null | wc -l)
        
        if [[ $total -eq 0 ]]; then
            log_error "No containers found"
            return 1
        fi
        
        if [[ $running -eq $total ]]; then
            # Check for restart loops
            local unhealthy=0
            for container in $(docker compose -f "$compose_file" ps -q 2>/dev/null); do
                local restarts=$(docker inspect --format='{{.RestartCount}}' "$container" 2>/dev/null || echo 0)
                local state=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
                
                if [[ $restarts -gt 3 ]]; then
                    log_warn "Container $container has restarted $restarts times"
                    unhealthy=$((unhealthy + 1))
                fi
                
                if [[ "$state" != "running" ]]; then
                    log_warn "Container $container is in state: $state"
                    unhealthy=$((unhealthy + 1))
                fi
            done
            
            if [[ $unhealthy -eq 0 ]]; then
                log_info "All $running containers are healthy"
                return 0
            fi
        fi
        
        log_info "Waiting... ($running/$total running)"
        sleep "$HEALTH_INTERVAL"
        attempt=$((attempt + 1))
    done
    
    log_error "Health check timeout after $HEALTH_TIMEOUT seconds"
    return 1
}

# Run integration tests
run_integration_tests() {
    local compose_file="$1"
    local service_dir=$(dirname "$compose_file")
    
    log_step "Running integration tests..."
    
    # Basic HTTP checks for services with traefik labels
    local has_traefik=$(grep -l "traefik.enable=true" "$compose_file" 2>/dev/null || true)
    if [[ -n "$has_traefik" ]]; then
        log_info "Service has Traefik labels (would be accessible via reverse proxy)"
    fi
    
    # Check container logs for obvious errors
    local error_count=0
    for container in $(docker compose -f "$compose_file" ps -q 2>/dev/null); do
        local errors=$(docker logs "$container" 2>&1 | grep -iE "(fatal|panic|exception|error.*fail)" | wc -l || echo 0)
        if [[ $errors -gt 5 ]]; then
            log_warn "Container $container has $errors potential error messages in logs"
            error_count=$((error_count + 1))
        fi
    done
    
    if [[ $error_count -gt 0 ]]; then
        log_warn "$error_count container(s) have error messages"
    else
        log_info "No obvious errors in container logs"
    fi
    
    return 0
}

# Cleanup service
cleanup_service() {
    local compose_file="$1"
    
    log_step "Cleaning up..."
    
    # Save disk usage before
    local before=$(df / | tail -1 | awk '{print $4}')
    
    # Stop and remove containers, volumes
    docker compose -f "$compose_file" down --volumes --remove-orphans 2>/dev/null || true
    
    # Remove images
    local images=$(docker compose -f "$compose_file" config 2>/dev/null | \
                   grep -E '^\s*image:' | \
                   sed 's/.*image:\s*//' | \
                   tr -d '"' || true)
    
    for img in $images; do
        docker rmi "$img" 2>/dev/null || true
    done
    
    # Prune system
    docker system prune -af --volumes 2>/dev/null || true
    
    # Report space freed
    local after=$(df / | tail -1 | awk '{print $4}')
    local freed=$((after - before))
    log_info "Cleaned up. Disk freed: ${freed}K"
}

# Main test function
test_service() {
    local service="$1"
    local no_cleanup="${2:-false}"
    
    local service_dir=$(get_service_dir "$service")
    local compose_file="$service_dir/docker-compose.yml"
    
    # Validate
    if [[ ! -d "$service_dir" ]]; then
        log_error "Service directory not found: $service_dir"
        return 1
    fi
    
    if [[ ! -f "$compose_file" ]]; then
        log_error "Compose file not found: $compose_file"
        return 1
    fi
    
    log_info "Testing service: $service"
    log_info "Compose file: $compose_file"
    
    local start_time=$(date +%s)
    local result=0
    
    # Load environment
    load_service_env "$service_dir"
    
    # Ensure traefik network exists
    docker network create traefik_default 2>/dev/null || true
    
    # Step 1: Pull images (quiet mode to reduce log noise)
    log_step "Pulling images..."
    if timeout "$PULL_TIMEOUT" docker compose -f "$compose_file" pull --quiet 2>&1; then
        log_info "Images pulled successfully"
    else
        log_warn "Some images may have failed to pull"
    fi
    
    # Step 2: Start services (quiet-pull to suppress download progress)
    log_step "Starting services..."
    if timeout "$START_TIMEOUT" docker compose -f "$compose_file" up -d --quiet-pull 2>&1; then
        log_info "Services started"
        
        # Wait for initial startup
        sleep 5
        
        # Step 3: Health checks
        log_step "Running health checks..."
        if check_container_health "$compose_file"; then
            log_info "Health checks passed"
            
            # Step 4: Integration tests
            if run_integration_tests "$compose_file"; then
                log_info "Integration tests passed"
            else
                log_warn "Some integration tests had warnings"
            fi
        else
            log_error "Health checks failed"
            result=1
        fi
    else
        log_error "Failed to start services"
        result=1
    fi
    
    # Show container status
    log_step "Container status:"
    docker compose -f "$compose_file" ps 2>/dev/null || true
    
    # Capture logs if failed
    if [[ $result -ne 0 ]]; then
        log_step "Container logs (last 50 lines):"
        docker compose -f "$compose_file" logs --tail=50 2>&1 || true
    fi
    
    # Cleanup unless skipped
    if [[ "$no_cleanup" != "--no-cleanup" ]]; then
        cleanup_service "$compose_file"
    else
        log_warn "Skipping cleanup (--no-cleanup specified)"
    fi
    
    # Report results
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    if [[ $result -eq 0 ]]; then
        log_info "TEST PASSED: $service (${duration}s)"
    else
        log_error "TEST FAILED: $service (${duration}s)"
    fi
    
    return $result
}

# Show usage
usage() {
    cat << EOF
Usage: $0 <service-name> [--no-cleanup]

Arguments:
    service-name    Name of the service directory under services/
    --no-cleanup    Skip cleanup after testing (useful for debugging)

Environment Variables:
    PULL_TIMEOUT    Timeout for pulling images (default: 300s)
    START_TIMEOUT   Timeout for starting services (default: 120s)
    HEALTH_TIMEOUT  Timeout for health checks (default: 180s)
    HEALTH_INTERVAL Interval between health checks (default: 10s)

Examples:
    $0 metabase
    $0 gitlab --no-cleanup

EOF
}

# Entry point
if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    usage
    exit 0
fi

test_service "$@"
