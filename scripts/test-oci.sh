#!/bin/bash
# test-oci.sh - Test OCI artifact deployment locally
# Usage: ./scripts/test-oci.sh <service> [version]

set -euo pipefail

SERVICE="${1:?Usage: $0 <service> [version]}"
VERSION="${2:-latest}"
REGISTRY="ghcr.io/beevelop"

echo "=== Testing OCI Artifact ==="
echo "Service:  ${SERVICE}"
echo "Version:  ${VERSION}"
echo "Registry: ${REGISTRY}"
echo ""

# Create minimal test environment
TEST_ENV=$(mktemp)
trap "rm -f ${TEST_ENV}" EXIT

cat > "${TEST_ENV}" << 'EOF'
COMPOSE_PROJECT_NAME=oci-test
SERVICE_DOMAIN=localhost
DB_PASS=testpassword123
DB_USER=testuser
DB_NAME=testdb
GITLAB_ROOT_PASSWORD=testpassword123
GITLAB_SECRETS_DB_KEY_BASE=1234567890123456789012345678901234567890123456789012345678901234
GITLAB_SECRETS_SECRET_KEY_BASE=1234567890123456789012345678901234567890123456789012345678901234
GITLAB_SECRETS_OTP_KEY_BASE=1234567890123456789012345678901234567890123456789012345678901234
GRAYLOG_PASSWORD_SECRET=1234567890123456789012345678901234567890123456789012345678901234
GRAYLOG_ROOT_PASSWORD_SHA2=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
CLOUDFLARE_EMAIL=test@example.com
CLOUDFLARE_API_KEY=test-api-key
TRAEFIK_DOMAIN=traefik.localhost
TRAEFIK_AUTH=test:test
EOF

echo "Using test environment:"
cat "${TEST_ENV}"
echo ""

OCI_URL="${REGISTRY}/${SERVICE}:${VERSION}"

# Check if we can pull the OCI artifact
echo "=== Pulling OCI Artifact ==="
if ! docker compose -f "oci://${OCI_URL}" --env-file "${TEST_ENV}" config > /dev/null 2>&1; then
  echo "ERROR: Failed to pull or parse OCI artifact: ${OCI_URL}"
  echo ""
  echo "This may mean:"
  echo "  - The artifact doesn't exist yet (not published)"
  echo "  - The version tag is incorrect"
  echo "  - Network/authentication issues"
  echo ""
  echo "To test locally without OCI, use:"
  echo "  cd services/${SERVICE}"
  echo "  docker compose --env-file .env.example up -d"
  exit 1
fi

echo "OCI artifact parsed successfully!"
echo ""

# Start the service
echo "=== Starting Service ==="
docker compose \
  -f "oci://${OCI_URL}" \
  --env-file "${TEST_ENV}" \
  up -d

# Wait for services to start
echo ""
echo "=== Waiting for services to start (30s) ==="
sleep 30

# Check status
echo ""
echo "=== Service Status ==="
docker compose \
  -f "oci://${OCI_URL}" \
  --env-file "${TEST_ENV}" \
  ps

# Show logs if any container is unhealthy
echo ""
echo "=== Container Health ==="
UNHEALTHY=$(docker ps --filter "name=oci-test" --filter "health=unhealthy" --format "{{.Names}}" 2>/dev/null || true)
if [[ -n "${UNHEALTHY}" ]]; then
  echo "WARNING: Some containers are unhealthy:"
  echo "${UNHEALTHY}"
  echo ""
  echo "=== Unhealthy Container Logs ==="
  for container in ${UNHEALTHY}; do
    echo "--- ${container} ---"
    docker logs --tail 50 "${container}" 2>&1 || true
  done
else
  echo "All containers are healthy or starting!"
fi

# Prompt for cleanup
echo ""
read -p "Press Enter to cleanup (Ctrl+C to keep running)..." || true

echo ""
echo "=== Cleaning Up ==="
docker compose \
  -f "oci://${OCI_URL}" \
  --env-file "${TEST_ENV}" \
  down -v --remove-orphans

echo ""
echo "=== Test Complete ==="
