# Testing Guide

This guide documents how to test BeeCompose services for OCI compatibility and deployment.

---

## Quick Start

```bash
# Validate all services for OCI compatibility
./scripts/validate-all-oci.sh

# Dry-run publish for a specific service
./scripts/publish-dry-run.sh gitlab

# Test OCI deployment (requires published artifact)
./scripts/test-oci.sh gitlab v18.8.0
```

---

## Testing Scripts

### validate-all-oci.sh

Validates all 30 services for OCI compatibility without requiring network access or published artifacts.

**Usage:**
```bash
./scripts/validate-all-oci.sh
```

**What it checks:**
| Check | Description | Blocking |
|-------|-------------|----------|
| Compose syntax | `docker compose config` must succeed | Yes |
| Bind mounts | No bind mounts except `/var/run/docker.sock` | Yes |
| Build directives | Warns if `build:` present (images must be pre-built) | Warning |

**Example output:**
```
=== Validating All Services for OCI Compatibility ===

bitwarden            PASS  -
gitlab               PASS  -
traefik              PASS  -
...

=== Summary ===
Passed: 30
Warnings: 0
Failed: 0
Total: 30

All services are OCI compatible!
```

**Exit codes:**
- `0` - All services pass (warnings allowed)
- `1` - One or more services failed validation

---

### publish-dry-run.sh

Performs a comprehensive pre-publish validation for a single service.

**Usage:**
```bash
./scripts/publish-dry-run.sh <service>
```

**Example:**
```bash
./scripts/publish-dry-run.sh gitlab
```

**Validation steps:**
1. Compose syntax validation
2. OCI compatibility check (bind mounts)
3. Build directive check
4. Local config file reference check
5. Version extraction from `.env`
6. Required files check (docker-compose.yml, .env)
7. DCLint validation (if Docker available)

**Example output:**
```
=== OCI Publishing Dry Run ===
Service: gitlab
Directory: /path/to/services/gitlab

=== Step 1: Validating Compose Syntax ===
PASS: Compose syntax is valid

=== Step 2: Checking OCI Compatibility ===
PASS: No problematic bind mounts
PASS: No build directives
PASS: No local config file references

=== Step 3: Extracting Version ===
Extracted version: v18.8.0

=== Step 4: Checking Required Files ===
PASS: docker-compose.yml exists
PASS: .env exists
PASS: .env.example exists (recommended)

=== Step 5: Running DCLint ===
PASS: DCLint validation passed

=== Dry Run Summary ===

Service:  gitlab
Version:  v18.8.0
Registry: ghcr.io/beevelop

Would publish:
  ghcr.io/beevelop/gitlab:v18.8.0
  ghcr.io/beevelop/gitlab:latest

To actually publish, run:
  docker compose publish -y ghcr.io/beevelop/gitlab:v18.8.0
  docker compose publish -y ghcr.io/beevelop/gitlab:latest

=== Dry Run Complete ===
```

---

### test-oci.sh

Tests an OCI artifact deployment end-to-end. Requires the artifact to be published to GHCR first.

**Usage:**
```bash
./scripts/test-oci.sh <service> [version]
```

**Examples:**
```bash
# Test latest version
./scripts/test-oci.sh gitlab

# Test specific version
./scripts/test-oci.sh gitlab v18.8.0
```

**What it does:**
1. Creates a temporary test environment file
2. Pulls the OCI artifact from GHCR
3. Starts all services
4. Waits 30 seconds for startup
5. Shows service status and health
6. Prompts for cleanup (Ctrl+C to keep running)
7. Removes containers and volumes

**Test environment variables:**
The script creates minimal test credentials for services:
- `COMPOSE_PROJECT_NAME=oci-test`
- `SERVICE_DOMAIN=localhost`
- `DB_PASS/DB_USER/DB_NAME` - Database credentials
- Service-specific secrets (GitLab, Graylog, etc.)

---

## Test Matrix

Use this matrix to verify service functionality:

| Test Case | Command | Pass Criteria |
|-----------|---------|---------------|
| **OCI Validation** | `./scripts/validate-all-oci.sh` | All 30 services PASS |
| **Dry-run Publish** | `./scripts/publish-dry-run.sh <service>` | No FAIL messages |
| **OCI Pull & Run** | `./scripts/test-oci.sh <service>` | Containers start |
| **Health Checks** | `docker compose ps` | All containers healthy |
| **Env Override** | `--env-file .env.custom` | Custom values applied |
| **Volume Persistence** | Stop, start, verify data | Data retained |
| **Multi-service** | traefik + app | Both routable |
| **Init Profile** | `--profile init up traefik-init` | Config generated |

---

## Local Testing Without OCI

For development, you can test services directly from the repository:

```bash
# Navigate to service directory
cd services/gitlab

# Create environment file
cp .env.example .env.local
# Edit .env.local with your values

# Start service
docker compose --env-file .env.local up -d

# Check status
docker compose ps

# View logs
docker compose logs -f

# Stop and cleanup
docker compose down -v
```

---

## CI/CD Testing

The GitHub Actions pipeline runs these tests automatically:

### Job 1: Lint (DCLint)
```yaml
- docker run --rm -v "$(pwd):/app" zavoloklom/dclint:latest /app/services -r -c /app/.dclintrc.yaml
```

### Job 2: Validate OCI
```yaml
- name: Check for OCI blockers
  run: |
    for COMPOSE in services/*/docker-compose.yml; do
      # Check for bind mounts, build directives, etc.
    done
```

### Job 3: Publish OCI (on main branch)
- Detects changed services
- Extracts version from `.env`
- Publishes to `ghcr.io/beevelop/<service>:<version>`
- Publishes `latest` tag

---

## Troubleshooting

### Service fails OCI validation

**Bind mount detected:**
```
FAIL: Contains bind mounts (not OCI compatible)
./data/app:/app/data
```

**Fix:** Convert to named volumes in `docker-compose.yml`:
```yaml
volumes:
  - app_data:/app/data

volumes:
  app_data:
    name: ${COMPOSE_PROJECT_NAME:-service}_app_data
```

### Compose syntax error

```
FAIL: Compose syntax error
```

**Fix:** Run `docker compose config` in the service directory to see the error:
```bash
cd services/<service>
docker compose config
```

### OCI artifact not found

```
ERROR: Failed to pull or parse OCI artifact
```

**Possible causes:**
- Artifact not published yet (use dry-run first)
- Version tag incorrect
- Authentication required (run `docker login ghcr.io`)
- Network issues

### Containers unhealthy

```
WARNING: Some containers are unhealthy
```

**Debug steps:**
1. Check container logs: `docker logs <container>`
2. Verify environment variables
3. Check healthcheck definition in compose file
4. Increase `start_period` for slow-starting services

---

## Adding Tests for New Services

When adding a new service, ensure it passes all validation:

```bash
# 1. Validate OCI compatibility
./scripts/publish-dry-run.sh <new-service>

# 2. Test locally
cd services/<new-service>
cp .env.example .env.test
docker compose --env-file .env.test up -d
docker compose ps
docker compose down -v

# 3. Verify all services still pass
./scripts/validate-all-oci.sh
```

---

## Test Results

Last validation run: **2026-01-21**

| Service | Status | Notes |
|---------|--------|-------|
| bitwarden | PASS | - |
| cabot | PASS | - |
| confluence | PASS | - |
| crowd | PASS | - |
| dependency-track | PASS | - |
| directus | PASS | - |
| duckling | PASS | - |
| gitlab | PASS | - |
| graylog | PASS | - |
| huginn | PASS | - |
| jira | PASS | - |
| keycloak | PASS | - |
| metabase | PASS | - |
| minio | PASS | - |
| monica | PASS | - |
| mysql | PASS | - |
| nexus | PASS | - |
| openvpn | PASS | - |
| phpmyadmin | PASS | - |
| redash | PASS | - |
| registry | PASS | - |
| rundeck | PASS | - |
| sentry | PASS | - |
| shields | PASS | - |
| sonarqube | PASS | - |
| statping | PASS | - |
| traefik | PASS | docker.sock bind mount allowed |
| tus | PASS | - |
| weblate | PASS | - |
| zabbix | PASS | - |

**Summary:** 30/30 services OCI compatible
