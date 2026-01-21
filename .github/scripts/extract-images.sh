#!/usr/bin/env bash
#
# extract-images.sh - Extract unique Docker images from compose files
#
# This script scans all Docker Compose files and extracts unique image references.
# It resolves environment variables from .env files.
#
# Usage: ./extract-images.sh [--json|--csv]
#

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Output format
OUTPUT_FORMAT="${1:-text}"

# Temp file for collecting images
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Find all compose files
find_compose_files() {
    find "$REPO_ROOT/services" -maxdepth 2 -name "docker-compose.yml" -type f | sort
}

# Extract images from a compose file
extract_from_compose() {
    local compose_file="$1"
    local service_dir=$(dirname "$compose_file")
    local service_name=$(basename "$service_dir")
    
    # Load environment variables
    if [[ -f "$service_dir/.env" ]]; then
        set -a
        source "$service_dir/.env" 2>/dev/null || true
        set +a
    fi
    
    if [[ -f "$service_dir/.env.example" ]]; then
        set -a
        source "$service_dir/.env.example" 2>/dev/null || true
        set +a
    fi
    
    # Extract images using docker compose config
    local images=$(docker compose -f "$compose_file" config 2>/dev/null | \
                   grep -E '^\s*image:' | \
                   sed 's/.*image:\s*//' | \
                   sed 's/[[:space:]]*$//' | \
                   tr -d '"' || true)
    
    for img in $images; do
        echo "$service_name:$img"
    done
}

# Main
main() {
    local compose_files=$(find_compose_files)
    
    # Extract all images with their service
    for file in $compose_files; do
        extract_from_compose "$file" >> "$TEMP_FILE"
    done
    
    # Process output based on format
    case "$OUTPUT_FORMAT" in
        --json)
            echo "{"
            echo '  "images": ['
            
            # Get unique images
            local unique_images=$(cut -d: -f2- "$TEMP_FILE" | sort -u)
            local first=true
            
            for img in $unique_images; do
                # Find services using this image
                local services=$(grep ":${img}$" "$TEMP_FILE" | cut -d: -f1 | sort -u | tr '\n' ',' | sed 's/,$//')
                
                if [[ "$first" == "true" ]]; then
                    first=false
                else
                    echo ","
                fi
                
                printf '    {"image": "%s", "services": [%s]}' "$img" "$(echo "$services" | sed 's/\([^,]*\)/"\1"/g')"
            done
            
            echo ""
            echo "  ],"
            echo "  \"total\": $(cut -d: -f2- "$TEMP_FILE" | sort -u | wc -l)"
            echo "}"
            ;;
            
        --csv)
            echo "image,services"
            local unique_images=$(cut -d: -f2- "$TEMP_FILE" | sort -u)
            
            for img in $unique_images; do
                local services=$(grep ":${img}$" "$TEMP_FILE" | cut -d: -f1 | sort -u | tr '\n' '|' | sed 's/|$//')
                echo "\"$img\",\"$services\""
            done
            ;;
            
        *)
            # Plain text format
            echo "=== Docker Images by Service ==="
            echo ""
            
            local current_service=""
            while IFS=: read -r service image; do
                if [[ "$service" != "$current_service" ]]; then
                    current_service="$service"
                    echo "[$service]"
                fi
                echo "  - $image"
            done < <(sort "$TEMP_FILE")
            
            echo ""
            echo "=== Unique Images ==="
            cut -d: -f2- "$TEMP_FILE" | sort -u
            
            echo ""
            echo "=== Summary ==="
            echo "Total services: $(find_compose_files | wc -l)"
            echo "Total images: $(wc -l < "$TEMP_FILE")"
            echo "Unique images: $(cut -d: -f2- "$TEMP_FILE" | sort -u | wc -l)"
            ;;
    esac
}

main
