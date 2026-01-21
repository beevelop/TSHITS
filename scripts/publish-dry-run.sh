#!/bin/bash
# publish-dry-run.sh - Validate OCI publishing locally without actually publishing
# Usage: ./scripts/publish-dry-run.sh <service>

set -euo pipefail

SERVICE="${1:?Usage: $0 <service>}"
REGISTRY="ghcr.io/beevelop"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
SERVICE_DIR="${REPO_ROOT}/services/${SERVICE}"

if [[ ! -d "${SERVICE_DIR}" ]]; then
  echo "ERROR: Service directory not found: ${SERVICE_DIR}"
  exit 1
fi

cd "${SERVICE_DIR}"

echo "=== OCI Publishing Dry Run ==="
echo "Service: ${SERVICE}"
echo "Directory: ${SERVICE_DIR}"
echo ""

# Step 1: Validate compose syntax
echo "=== Step 1: Validating Compose Syntax ==="
if docker compose config > /dev/null 2>&1; then
  echo "PASS: Compose syntax is valid"
else
  echo "FAIL: Compose syntax error"
  docker compose config
  exit 1
fi
echo ""

# Step 2: Check for OCI blockers
echo "=== Step 2: Checking OCI Compatibility ==="
ERRORS=0

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
  echo "FAIL: Contains bind mounts (not OCI compatible)"
  echo "${PROBLEM_BINDS}"
  ERRORS=$((ERRORS+1))
else
  echo "PASS: No problematic bind mounts"
fi

# Check for build directives
if grep -qE '^\s+build:' docker-compose.yml 2>/dev/null; then
  echo "WARN: Contains build directive (images must be pre-built)"
else
  echo "PASS: No build directives"
fi

# Check for local config file references
if grep -qE '^\s+-\s+\./[^/]+\.(yml|yaml|conf|env):' docker-compose.yml 2>/dev/null; then
  echo "WARN: References local config files"
else
  echo "PASS: No local config file references"
fi

if [[ ${ERRORS} -gt 0 ]]; then
  echo ""
  echo "FAIL: Service has OCI blockers"
  exit 1
fi
echo ""

# Step 3: Extract version
echo "=== Step 3: Extracting Version ==="
if [[ -f .env ]]; then
  VERSION=$(grep -E '_VERSION=' .env 2>/dev/null | head -1 | cut -d'=' -f2 || echo "latest")
else
  VERSION="latest"
fi

# Normalize: add 'v' prefix if starts with number
if [[ "${VERSION}" =~ ^[0-9] ]]; then
  VERSION="v${VERSION}"
fi

echo "Extracted version: ${VERSION}"
echo ""

# Step 4: Check required files
echo "=== Step 4: Checking Required Files ==="
REQUIRED_FILES=("docker-compose.yml" ".env")
MISSING=0

for file in "${REQUIRED_FILES[@]}"; do
  if [[ -f "${file}" ]]; then
    echo "PASS: ${file} exists"
  else
    echo "FAIL: ${file} missing"
    MISSING=$((MISSING+1))
  fi
done

if [[ -f ".env.example" ]]; then
  echo "PASS: .env.example exists (recommended)"
else
  echo "WARN: .env.example missing (recommended)"
fi

if [[ ${MISSING} -gt 0 ]]; then
  echo ""
  echo "FAIL: Missing required files"
  exit 1
fi
echo ""

# Step 5: Run DCLint
echo "=== Step 5: Running DCLint ==="
if command -v docker &> /dev/null; then
  if docker run --rm -v "${REPO_ROOT}:/app" zavoloklom/dclint:latest "/app/services/${SERVICE}" -c /app/.dclintrc.yaml 2>/dev/null; then
    echo "PASS: DCLint validation passed"
  else
    echo "WARN: DCLint found issues (may not be blocking)"
  fi
else
  echo "SKIP: Docker not available for DCLint"
fi
echo ""

# Summary
echo "=== Dry Run Summary ==="
echo ""
echo "Service:  ${SERVICE}"
echo "Version:  ${VERSION}"
echo "Registry: ${REGISTRY}"
echo ""
echo "Would publish:"
echo "  ${REGISTRY}/${SERVICE}:${VERSION}"
echo "  ${REGISTRY}/${SERVICE}:latest"
echo ""
echo "To actually publish, run:"
echo "  docker compose publish -y ${REGISTRY}/${SERVICE}:${VERSION}"
echo "  docker compose publish -y ${REGISTRY}/${SERVICE}:latest"
echo ""
echo "=== Dry Run Complete ==="
