#!/bin/bash
# validate-all-oci.sh - Validate all services for OCI compatibility
# Usage: ./scripts/validate-all-oci.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
SERVICES_DIR="${REPO_ROOT}/services"

echo "=== Validating All Services for OCI Compatibility ==="
echo ""

PASS=0
FAIL=0
WARN=0

# Create results array
declare -a RESULTS

for SERVICE_DIR in "${SERVICES_DIR}"/*/; do
  SERVICE=$(basename "${SERVICE_DIR}")
  
  # Skip if no docker-compose.yml
  if [[ ! -f "${SERVICE_DIR}/docker-compose.yml" ]]; then
    continue
  fi
  
  cd "${SERVICE_DIR}"
  STATUS="PASS"
  NOTES=""
  
  # Check compose syntax
  if ! docker compose config > /dev/null 2>&1; then
    STATUS="FAIL"
    NOTES="Compose syntax error"
  else
    # Check for bind mounts (except docker.sock)
    # Use awk to check bind mount blocks - only fail if source is NOT docker.sock
    CONFIG=$(docker compose config 2>/dev/null)
    PROBLEM_BINDS=$(echo "${CONFIG}" | awk '
      /type: bind/ { in_bind=1; next }
      in_bind && /source:/ { 
        if ($2 !~ /docker\.sock/) print $2
        in_bind=0
      }
    ' || true)
    if [[ -n "${PROBLEM_BINDS}" ]]; then
      STATUS="FAIL"
      NOTES="Bind mounts"
    fi
    
    # Check for build directives
    if grep -qE '^\s+build:' docker-compose.yml 2>/dev/null; then
      if [[ "${STATUS}" == "PASS" ]]; then
        STATUS="WARN"
        NOTES="Build directive"
      else
        NOTES="${NOTES}, Build directive"
      fi
    fi
  fi
  
  # Count results
  case "${STATUS}" in
    PASS) PASS=$((PASS+1)) ;;
    FAIL) FAIL=$((FAIL+1)) ;;
    WARN) WARN=$((WARN+1)) ;;
  esac
  
  # Store result
  if [[ -z "${NOTES}" ]]; then
    NOTES="-"
  fi
  printf "%-20s %s  %s\n" "${SERVICE}" "${STATUS}" "${NOTES}"
done

echo ""
echo "=== Summary ==="
echo "Passed: ${PASS}"
echo "Warnings: ${WARN}"
echo "Failed: ${FAIL}"
echo "Total: $((PASS+WARN+FAIL))"
echo ""

if [[ ${FAIL} -gt 0 ]]; then
  echo "Some services failed OCI validation!"
  exit 1
else
  echo "All services are OCI compatible!"
  exit 0
fi
