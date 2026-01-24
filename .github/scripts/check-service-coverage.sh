#!/usr/bin/env bash
# check-service-coverage.sh - Verify all services are documented in all required locations
#
# This script ensures that when a new service is added to the services/ directory,
# it is also added to:
#   1. README.md - Services table (user-facing documentation)
#   2. scripts/bc - cmd_list() function (CLI helper service list)
#   3. .github/workflows/check-versions.yml - IMAGE_REGISTRIES array (version checking)
#   4. .github/dependabot.yml - Per-service docker-compose monitoring
#
# Usage: ./scripts/check-service-coverage.sh [--fix-hints]
#
# Exit codes:
#   0 - All services are properly documented everywhere
#   1 - Missing coverage detected

set -euo pipefail

# Find the repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Files to check
README_FILE="${REPO_ROOT}/README.md"
BC_CLI="${REPO_ROOT}/scripts/bc"
CHECK_VERSIONS="${REPO_ROOT}/.github/workflows/check-versions.yml"
DEPENDABOT="${REPO_ROOT}/.github/dependabot.yml"

# Colors for output
if [[ -t 1 ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[0;33m'
  readonly CYAN='\033[0;36m'
  readonly BOLD='\033[1m'
  readonly NC='\033[0m'
else
  readonly RED='' GREEN='' YELLOW='' CYAN='' BOLD='' NC=''
fi

# Counters
TOTAL_MISSING=0
SHOW_FIX_HINTS=false

# Parse arguments
if [[ "${1:-}" == "--fix-hints" ]]; then
  SHOW_FIX_HINTS=true
fi

log() {
  echo -e "${CYAN}[check]${NC} $*"
}

pass() {
  echo -e "${GREEN}  ✓${NC} $*"
}

fail() {
  echo -e "${RED}  ✗${NC} $*"
  TOTAL_MISSING=$((TOTAL_MISSING + 1))
}

warn() {
  echo -e "${YELLOW}  ⚠${NC} $*"
}

header() {
  echo ""
  echo -e "${BOLD}=== $* ===${NC}"
}

# Get all service directories
get_all_services() {
  find "${REPO_ROOT}/services" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort
}

# Check README.md services table
check_readme() {
  header "Checking README.md services table"
  
  local missing=0
  local services
  services=$(get_all_services)
  
  for service in $services; do
    # Look for service link pattern: [service](services/service/README.md)
    if grep -qE "^\| \[${service}\]\(services/${service}/README\.md\)" "$README_FILE" 2>/dev/null; then
      pass "$service"
    else
      fail "$service - not in README.md services table"
      missing=$((missing + 1))
      
      if [[ "$SHOW_FIX_HINTS" == "true" ]]; then
        echo -e "    ${YELLOW}Fix: Add this line to the services table in README.md:${NC}"
        echo "    | [$service](services/$service/README.md) | Description here | \`ghcr.io/beevelop/$service\` |"
      fi
    fi
  done
  
  if [[ $missing -eq 0 ]]; then
    echo -e "\n${GREEN}README.md: All services documented${NC}"
  else
    echo -e "\n${RED}README.md: $missing service(s) missing${NC}"
  fi
  
  return 0
}

# Check scripts/bc cmd_list() function
check_bc_cli() {
  header "Checking scripts/bc cmd_list()"
  
  local missing=0
  local services
  services=$(get_all_services)
  
  for service in $services; do
    # Look for service in the echo statements of cmd_list()
    # Pattern: echo "  service  - Description"
    if grep -qE "echo \"\s+${service}\s+" "$BC_CLI" 2>/dev/null; then
      pass "$service"
    else
      fail "$service - not in bc CLI list command"
      missing=$((missing + 1))
      
      if [[ "$SHOW_FIX_HINTS" == "true" ]]; then
        echo -e "    ${YELLOW}Fix: Add this line to cmd_list() in scripts/bc:${NC}"
        # Calculate padding for alignment (20 chars total for service name)
        local padding=$((18 - ${#service}))
        local spaces=""
        for ((i=0; i<padding; i++)); do spaces+=" "; done
        echo "    echo \"  $service$spaces- Description here\""
      fi
    fi
  done
  
  if [[ $missing -eq 0 ]]; then
    echo -e "\n${GREEN}scripts/bc: All services documented${NC}"
  else
    echo -e "\n${RED}scripts/bc: $missing service(s) missing${NC}"
  fi
  
  return 0
}

# Check .github/workflows/check-versions.yml IMAGE_REGISTRIES
check_version_workflow() {
  header "Checking check-versions.yml IMAGE_REGISTRIES"
  
  local missing=0
  local documented=0
  local services
  services=$(get_all_services)
  
  for service in $services; do
    # Look for service in the IMAGE_REGISTRIES array
    # Pattern: ["service"]="registry/image"
    if grep -qE "^\s*\[\"${service}\"\]=" "$CHECK_VERSIONS" 2>/dev/null; then
      pass "$service"
      documented=$((documented + 1))
    else
      warn "$service - not in IMAGE_REGISTRIES (version checking disabled)"
      missing=$((missing + 1))
      
      if [[ "$SHOW_FIX_HINTS" == "true" ]]; then
        echo -e "    ${YELLOW}Fix: Add to IMAGE_REGISTRIES in check-versions.yml:${NC}"
        echo "    [\"$service\"]=\"registry/image-name\""
      fi
    fi
  done
  
  # This is a warning, not an error - version checking is optional
  if [[ $missing -eq 0 ]]; then
    echo -e "\n${GREEN}check-versions.yml: All services have version checking configured${NC}"
  else
    echo -e "\n${YELLOW}check-versions.yml: $missing service(s) without version checking${NC}"
    echo -e "  (This is optional - add registry mapping to enable automatic version updates)"
  fi
  
  # Don't count these as failures - version checking is optional
  return 0
}

# Check .github/dependabot.yml
check_dependabot() {
  header "Checking dependabot.yml"
  
  local missing=0
  local documented=0
  local services
  services=$(get_all_services)
  
  for service in $services; do
    # Look for service directory in dependabot config
    # Pattern: directory: "/services/service"
    if grep -qE "directory:\s*\"/services/${service}\"" "$DEPENDABOT" 2>/dev/null; then
      pass "$service"
      documented=$((documented + 1))
    else
      warn "$service - not in dependabot.yml (automatic updates disabled)"
      missing=$((missing + 1))
      
      if [[ "$SHOW_FIX_HINTS" == "true" ]]; then
        echo -e "    ${YELLOW}Fix: Add this block to dependabot.yml:${NC}"
        cat << EOF
  - package-ecosystem: "docker-compose"
    directory: "/services/$service"
    schedule:
      interval: "weekly"
      day: "tuesday"
      time: "06:00"
      timezone: "UTC"
    commit-message:
      prefix: "$(echo "$service" | sed 's/.*/\u&/')"
    labels:
      - "dependencies"
      - "docker"
    open-pull-requests-limit: 3
EOF
      fi
    fi
  done
  
  # This is a warning, not an error - dependabot is optional
  if [[ $missing -eq 0 ]]; then
    echo -e "\n${GREEN}dependabot.yml: All services have dependabot configured${NC}"
  else
    echo -e "\n${YELLOW}dependabot.yml: $missing service(s) without dependabot monitoring${NC}"
    echo -e "  (This is optional - add entry to enable automatic Dependabot PRs)"
  fi
  
  # Don't count these as failures - dependabot is optional
  return 0
}

# Count services in each location
show_summary() {
  header "Summary"
  
  local service_count
  service_count=$(get_all_services | wc -l | tr -d ' ')
  
  local readme_count
  readme_count=$(grep -cE "^\| \[.*\]\(services/.*/README\.md\)" "$README_FILE" 2>/dev/null || echo 0)
  
  local bc_count
  # Count echo statements in cmd_list() that look like service entries
  bc_count=$(grep -cE "^\s*echo \"\s+[a-z0-9-]+\s+-" "$BC_CLI" 2>/dev/null || echo 0)
  
  local versions_count
  versions_count=$(grep -cE "^\s*\[\"[a-z0-9-]+\"\]=" "$CHECK_VERSIONS" 2>/dev/null || echo 0)
  
  local dependabot_count
  dependabot_count=$(grep -cE "directory:\s*\"/services/[a-z0-9-]+\"" "$DEPENDABOT" 2>/dev/null || echo 0)
  
  echo ""
  echo "Service Directories:         $service_count"
  echo "README.md Services Table:    $readme_count"
  echo "scripts/bc cmd_list():       $bc_count"
  echo "check-versions.yml:          $versions_count (optional)"
  echo "dependabot.yml:              $dependabot_count (optional)"
  echo ""
  
  if [[ "$readme_count" -ne "$service_count" ]] || [[ "$bc_count" -ne "$service_count" ]]; then
    echo -e "${RED}${BOLD}CRITICAL: README.md and/or scripts/bc are out of sync!${NC}"
    echo ""
    echo "Required coverage (MUST match service count):"
    echo "  - README.md services table"
    echo "  - scripts/bc cmd_list() function"
    echo ""
    echo "Optional coverage (for automation):"
    echo "  - check-versions.yml IMAGE_REGISTRIES"
    echo "  - dependabot.yml docker-compose entries"
    return 1
  else
    echo -e "${GREEN}Required coverage is complete!${NC}"
    return 0
  fi
}

# Main
main() {
  echo ""
  echo -e "${BOLD}=======================================${NC}"
  echo -e "${BOLD}  BeeCompose Service Coverage Check${NC}"
  echo -e "${BOLD}=======================================${NC}"
  
  check_readme
  check_bc_cli
  check_version_workflow
  check_dependabot
  
  if ! show_summary; then
    echo ""
    echo -e "${RED}Service coverage check FAILED${NC}"
    echo ""
    echo "Run with --fix-hints to see how to fix:"
    echo "  ./.github/scripts/check-service-coverage.sh --fix-hints"
    echo ""
    exit 1
  fi
  
  echo -e "${GREEN}Service coverage check PASSED${NC}"
  echo ""
}

main "$@"
