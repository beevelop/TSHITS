#!/usr/bin/env bash
#
# extract-images.sh - Extract unique Docker images from compose files
#
# This script scans all Docker Compose files and extracts unique image references.
# It resolves environment variables from .env files.
#
# Usage: ./extract-images.sh [--json|--csv]
#

# Use set -u for undefined vars, but NOT set -e as it causes issues with grep/pipelines
set -uo pipefail

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
    # Disable nounset (-u) temporarily as env files may contain $ characters in values
    # that look like unset variables (e.g., bcrypt hashes like $2y$10$...)
    set +u
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
    set -u
    
    # Extract images using docker compose config
    # Use sed to trim leading/trailing whitespace from image names
    local images=$(docker compose -f "$compose_file" config 2>/dev/null | \
                   grep -E '^\s*image:' | \
                   sed 's/.*image://' | \
                   sed 's/^[[:space:]]*//' | \
                   sed 's/[[:space:]]*$//' | \
                   tr -d '"' || true)
    
    # Use while read to properly handle each line
    while IFS= read -r img; do
        if [[ -n "$img" ]]; then
            echo "$service_name:$img"
        fi
    done <<< "$images"
}

# Main
main() {
    # Extract all images with their service using proper line-by-line reading
    while IFS= read -r file; do
        extract_from_compose "$file" >> "$TEMP_FILE"
    done < <(find_compose_files)
    
    # Check if we got any images
    if [[ ! -s "$TEMP_FILE" ]]; then
        echo "ERROR: No images found" >&2
        exit 1
    fi
    
    # Process output based on format
    case "$OUTPUT_FORMAT" in
        --json)
            echo "{"
            echo '  "images": ['
            
            # Get unique images - use while read instead of for loop
            local first=true
            
            while IFS= read -r img; do
                [[ -z "$img" ]] && continue
                
                # Find services using this image (escape special chars for grep)
                local escaped_img=$(printf '%s\n' "$img" | sed 's/[[\.*^$()+?{|]/\\&/g')
                local services=$(grep ":${escaped_img}$" "$TEMP_FILE" | cut -d: -f1 | sort -u | tr '\n' ',' | sed 's/,$//')
                
                if [[ "$first" == "true" ]]; then
                    first=false
                else
                    echo ","
                fi
                
                printf '    {"image": "%s", "services": [%s]}' "$img" "$(echo "$services" | sed 's/\([^,]*\)/"\1"/g')"
            done < <(cut -d: -f2- "$TEMP_FILE" | sort -u)
            
            echo ""
            echo "  ],"
            echo "  \"total\": $(cut -d: -f2- "$TEMP_FILE" | sort -u | wc -l | tr -d ' ')"
            echo "}"
            ;;
            
        --csv)
            echo "image,services"
            
            while IFS= read -r img; do
                [[ -z "$img" ]] && continue
                local escaped_img=$(printf '%s\n' "$img" | sed 's/[[\.*^$()+?{|]/\\&/g')
                local services=$(grep ":${escaped_img}$" "$TEMP_FILE" | cut -d: -f1 | sort -u | tr '\n' '|' | sed 's/|$//')
                echo "\"$img\",\"$services\""
            done < <(cut -d: -f2- "$TEMP_FILE" | sort -u)
            ;;
            
        *)
            # Plain text format
            echo "=== Docker Images by Service ==="
            echo ""
            
            local current_service=""
            # Use tab as delimiter since service names don't contain tabs
            # Format in temp file is: service_name:image:tag
            # We need to split only on the FIRST colon
            while IFS= read -r line; do
                local service="${line%%:*}"
                local image="${line#*:}"
                
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
            echo "Total services: $(find_compose_files | wc -l | tr -d ' ')"
            echo "Total images: $(wc -l < "$TEMP_FILE" | tr -d ' ')"
            echo "Unique images: $(cut -d: -f2- "$TEMP_FILE" | sort -u | wc -l | tr -d ' ')"
            ;;
    esac
}

main
