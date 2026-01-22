# CI/CD Pipeline Documentation

This document describes the GitHub Actions CI/CD pipeline for BeeCompose, including how to use it, interpret results, and troubleshoot common issues.

## Table of Contents

1. [Overview](#overview)
2. [Pipeline Architecture](#pipeline-architecture)
3. [OCI Publishing](#oci-publishing)
4. [Automated Updates](#automated-updates)
5. [Adding New Services](#adding-new-services)
6. [Interpreting Results](#interpreting-results)
7. [CVE Scanning Policy](#cve-scanning-policy)
8. [Troubleshooting](#troubleshooting)
9. [Manual Workflow Triggers](#manual-workflow-triggers)
10. [Performance Considerations](#performance-considerations)

---

## Overview

The CI/CD pipeline automatically validates all Docker Compose configurations and scans container images for security vulnerabilities on every push and pull request.

### Key Features

- **OCI Publishing**: Compose files are published as OCI artifacts to GitHub Container Registry
- **OCI Validation**: Ensures all services are OCI-compatible (no bind mounts, no build directives)
- **Sequential Testing**: All 30 services are tested one after another to prevent resource conflicts
- **Aggressive Cleanup**: Docker images and volumes are removed between tests to prevent disk exhaustion
- **CVE Scanning**: All unique Docker images are scanned using Trivy for known vulnerabilities
- **Clear Reporting**: Detailed summaries and artifacts for debugging failures

### Triggers

The pipeline runs on:
- Push to `main`, `master`, or `develop` branches (when `services/**` or `.github/**` files change)
- Pull requests targeting `main` or `master`
- Manual workflow dispatch

---

## Pipeline Architecture

### Workflows

BeeCompose uses multiple GitHub Actions workflows:

| Workflow | File | Purpose | Trigger |
|----------|------|---------|---------|
| CI/CD Pipeline | `ci-cd.yml` | Lint, validate, scan, test | Push, PR |
| Publish OCI | `publish-oci.yml` | Publish OCI artifacts to GHCR | Push to main, release |
| Check Versions | `check-versions.yml` | Check upstream for new releases | Weekly, manual |

Additionally, **Dependabot** is configured via `.github/dependabot.yml` to monitor base images.

### Jobs Overview (CI/CD Pipeline)

```
┌─────────────────┐
│      lint       │  Validate compose files with DCLint
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  validate-oci   │  Check OCI compatibility (no bind mounts, no build)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    discover     │  Discover all services and validate compose syntax
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ extract-images  │  Extract unique Docker images from all compose files
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    cve-scan     │  Batch scan images with Trivy (blocks on CRITICAL)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ test-services   │  Sequential Docker Compose testing with cleanup
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    summary      │  Generate final report and GitHub Step Summary
└─────────────────┘
```

### Job Details

#### 1. Lint
- Validates all docker-compose.yml files with DCLint
- Checks for style issues, ordering, and best practices
- Uses `.dclintrc.yaml` configuration

#### 2. Validate OCI
- Ensures services are OCI-compatible
- Checks for bind mounts (except docker.sock)
- Checks for build directives
- Checks for local config file references
- **Fails pipeline if OCI blockers found**

#### 3. Discover Services
- Finds all `docker-compose.yml` files under `services/`
- Validates YAML syntax using `docker compose config`
- Outputs list of services for subsequent jobs

#### 4. Extract Images
- Parses each compose file to extract image references
- Resolves environment variables from `.env` and `.env.example`
- Deduplicates images (many services share postgres, redis, etc.)

#### 5. CVE Scan
- Installs Trivy vulnerability scanner
- Scans each unique image once
- Reports vulnerability counts by severity
- **Reports findings but does not block pipeline** (informational only)
- Cleans up images after scanning to save disk space

#### 6. Test Services
- Tests each service sequentially:
  1. Load environment variables
  2. Pull images
  3. Start containers with `docker compose up -d`
  4. Wait for services to stabilize
  5. Verify containers are running (not in restart loop)
  6. Capture logs for failed tests
  7. **Aggressive cleanup**: remove containers, volumes, AND images
- Reports pass/fail for each service

#### 7. Summary
- Generates GitHub Step Summary with overall results
- Reports metrics (services tested, images scanned, CVE counts)

---

## OCI Publishing

BeeCompose services are published as OCI artifacts to GitHub Container Registry (GHCR), enabling one-command deployments without cloning the repository.

### How Publishing Works

The `publish-oci.yml` workflow:

1. **Triggers** on push to main, manual dispatch, or releases
2. **Detects** which services changed (or publishes all on release)
3. **Extracts** version from the service's `.env` file
4. **Validates** compose syntax and OCI compatibility
5. **Publishes** to `ghcr.io/beevelop/<service>:<version>` and `:latest`

### Published Artifacts

All 30 services are published to:

```
ghcr.io/beevelop/<service>:<version>
ghcr.io/beevelop/<service>:latest
```

Examples:
- `ghcr.io/beevelop/gitlab:v16.0.0`
- `ghcr.io/beevelop/traefik:v3.3.0`
- `ghcr.io/beevelop/metabase:latest`

### Versioning

Versions are extracted from each service's `.env` file:

```bash
# services/gitlab/.env
GITLAB_VERSION=16.0.0

# Published as: ghcr.io/beevelop/gitlab:v16.0.0
```

**Normalization rules:**
- Version starting with a number gets `v` prefix: `16.0.0` → `v16.0.0`
- Version already prefixed is kept as-is: `v3.3.0` → `v3.3.0`
- Always publishes `:latest` tag alongside versioned tag

### Manual Publishing

Trigger a manual publish from GitHub Actions:

1. Go to **Actions** > **Publish OCI Artifacts**
2. Click **Run workflow**
3. Optionally specify:
   - `service`: Specific service to publish (empty = changed only)
   - `version_override`: Override the version tag

### Using Published Artifacts

Deploy any service directly from GHCR:

```bash
# Create environment file
cat > gitlab.env << 'EOF'
COMPOSE_PROJECT_NAME=gitlab
SERVICE_DOMAIN=gitlab.example.com
DB_PASS=secure-password
EOF

# Deploy from OCI
docker compose \
  -f oci://ghcr.io/beevelop/gitlab:latest \
  --env-file gitlab.env \
  up -d
```

### OCI Compatibility Requirements

For a service to be OCI-publishable:

| Requirement | Description |
|-------------|-------------|
| Named volumes | No `./data/` bind mounts (except docker.sock) |
| No build | Must use pre-built images only |
| No local configs | Config files must be generated or inlined |
| Valid compose | `docker compose config` must succeed |

The `validate-oci` job in CI enforces these requirements.

### Multi-Architecture Support

OCI artifacts published by BeeCompose are **architecture-agnostic**. The compose files reference base images (Traefik, PostgreSQL, Redis, etc.) that are already multi-architecture on Docker Hub and other registries.

When deploying, Docker automatically selects the correct architecture variant:

```bash
# Works on both amd64 and arm64
docker compose -f oci://ghcr.io/beevelop/metabase:latest up -d
```

**Supported architectures** (depends on base image):
- `linux/amd64` (x86_64)
- `linux/arm64` (aarch64, Apple Silicon, AWS Graviton)

---

## Automated Updates

BeeCompose includes automated systems to keep services up-to-date with upstream releases.

### Dependabot

Dependabot monitors Docker Compose files for base image updates and creates PRs automatically.

**Configuration:** `.github/dependabot.yml`

**How it works:**
1. Checks each service's `docker-compose.yml` weekly
2. Detects when new versions of base images are available
3. Creates a PR to update the image tag
4. PRs are labeled by category (devops, security, monitoring, etc.)

**Schedule:**
| Day | Categories |
|-----|------------|
| Monday | GitHub Actions |
| Tuesday | Infrastructure, Atlassian |
| Wednesday | DevOps tools |
| Thursday | Monitoring |
| Friday | Security |
| Saturday | Analytics, Productivity |
| Sunday | Storage, Databases, Misc |

### Upstream Version Checker

A custom workflow checks upstream registries for new stable releases and creates PRs.

**Workflow:** `.github/workflows/check-versions.yml`

**How it works:**
1. Runs weekly (Sundays at 05:00 UTC) or on manual trigger
2. For each service, queries Docker Hub/Quay for latest stable tag
3. Compares with current version in `.env`
4. Creates a PR if a newer stable version is available

**Filters applied:**
- Excludes pre-release tags (`-alpha`, `-beta`, `-rc`, `-dev`)
- Excludes non-semantic versions (`latest`, `nightly`, `edge`)
- Uses semantic version sorting to find the highest stable release

**Manual trigger:**
1. Go to **Actions** > **Check Upstream Versions**
2. Click **Run workflow**
3. Optionally specify a single service
4. Set `dry_run` to check without creating PRs

### Update Workflow

When either system creates a PR:

1. **Review** the PR and check upstream changelog for breaking changes
2. **CI runs** automatically to validate the update
3. **Merge** when satisfied
4. **OCI artifacts** are automatically published with the new version

---

## Adding New Services

When adding a new service to BeeCompose, ensure it works with the CI/CD pipeline:

### Requirements

1. **Directory Structure**
   ```
   services/<service-name>/
   ├── docker-compose.yml    # Required
   ├── .env                  # Required (image versions)
   └── .env.example          # Recommended (example config)
   ```

2. **Environment Variables**
   - Use `${VAR}` substitution in compose files
   - Define version tags in `.env` (committed)
   - Provide example values in `.env.example` (committed)

3. **OCI Compatibility**
   - Use named volumes (not bind mounts like `./data/`)
   - Exception: `/var/run/docker.sock` bind mount is allowed
   - Do not use `build:` directive - use pre-built images only
   - Include native Docker healthcheck directives

4. **Compose File Standards**
   ```yaml
   version: "3"
   name: myservice
   services:
     myservice:
       image: myimage:${MYSERVICE_VERSION}
       container_name: myservice
       volumes:
         - app_data:/app/data
       restart: unless-stopped
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost/health"]
         interval: 30s
         timeout: 10s
         retries: 3
         start_period: 30s
       logging:
         driver: "json-file"
         options:
           max-size: "500k"
           max-file: "50"
   
   volumes:
     app_data:
       name: ${COMPOSE_PROJECT_NAME:-myservice}_app_data
   
   networks:
     traefik:
       external:
         name: traefik_default
   ```

### Testing Locally

Before pushing, validate your compose file:

```bash
# Validate syntax
cd services/<service-name>
docker compose config

# Run DCLint
docker run --rm -v "$(pwd):/app" zavoloklom/dclint:latest /app/services/<service-name> -c /app/.dclintrc.yaml

# Check OCI compatibility (no bind mounts except docker.sock)
docker compose config | grep -E 'type: bind' | grep -v docker.sock
# Should output nothing

# Test locally
docker compose --env-file .env.example up -d
docker compose ps  # Verify (healthy) status
docker compose down
```

### Pipeline Considerations

- **OCI Validation**: Services with bind mounts will fail the `validate-oci` job
- **Health Checks**: The pipeline verifies containers start and don't enter restart loops
- **Resource Usage**: Large images may take longer to pull; adjust expectations
- **External Dependencies**: Services that require external APIs may not fully function in CI

---

## Interpreting Results

### Workflow Summary

After each run, check the **Actions** tab for:

1. **Job Status**: Green checkmark = passed, Red X = failed
2. **Step Summary**: Click on the run to see the generated summary
3. **Artifacts**: Download detailed results:
   - `cve-scan-results`: Full vulnerability reports per image
   - `docker-compose-test-results`: Test results and logs for failed services

### CVE Scan Results

The summary includes a table like:

| Image | Critical | High | Medium | Low | Status |
|-------|----------|------|--------|-----|--------|
| `postgres:13-alpine` | 0 | 2 | 5 | 10 | HIGH |
| `redis:latest` | 0 | 0 | 1 | 3 | PASS |
| `myapp:1.0` | 1 | 0 | 0 | 0 | CRITICAL |

- **CRITICAL/HIGH**: Warning shown in summary
- **PASS**: No high-severity issues

### Test Results

The summary includes:

| Service | Status | Duration | Details |
|---------|--------|----------|---------|
| metabase | PASS | 45s | All containers running |
| gitlab | FAIL | 120s | Container health issues |

For failed tests, check:
1. The `docker-compose-test-results` artifact
2. The `<service>-logs.txt` file for container logs

---

## CVE Scanning Policy

### Current Policy

| Severity | Action |
|----------|--------|
| CRITICAL | **Warning** - reported in scan results, does not block |
| HIGH | Warning only (logged in report) |
| MEDIUM | Informational |
| LOW | Informational |

> **Note:** CVE scanning is currently configured as informational only. This allows tracking vulnerabilities without blocking deployments for upstream issues beyond our control.

### Enabling Stricter Policy

To make CVE scanning blocking, modify the workflow file:

1. Open `.github/workflows/ci-cd.yml`
2. Set `CVE_FAIL_ON_CRITICAL: true` and/or `CVE_FAIL_ON_HIGH: true`
3. Update the `cve-scan` job to fail when thresholds are exceeded

Or use manual workflow dispatch with `fail_on_high` set to `true` for one-time strict scanning.

### Handling False Positives

If a CVE is a false positive or accepted risk:

1. Document the exception in the service's README
2. Consider pinning to a specific image digest
3. Create an issue to track resolution

---

## Troubleshooting

### Common Issues

#### 1. "Out of disk space" errors

**Cause**: Too many images pulled without cleanup

**Solution**: The pipeline includes aggressive cleanup, but if issues persist:
- Check that cleanup step runs even on failure
- Consider reducing parallel image pulls
- Review if any service stores large amounts of data

#### 2. Service fails to start

**Cause**: Missing environment variables or dependencies

**Solution**:
1. Check if `.env` has all required version tags
2. Check if `.env.example` has all required variables
3. Review logs in the `docker-compose-test-results` artifact

#### 3. Health check timeout

**Cause**: Service takes too long to start

**Solution**:
- Services have 3 minutes for health checks by default
- Some services (GitLab, Sentry) may need more time
- Check if the service has startup dependencies that aren't satisfied

#### 4. Image pull failures

**Cause**: Private image or rate limiting

**Solution**:
- Ensure images are publicly accessible
- For Docker Hub, consider adding registry auth
- Check if image tag exists

#### 5. CVE scan skips images

**Cause**: Image doesn't exist or can't be pulled

**Solution**:
- Check if image name/tag is correct
- Verify the image is published to the registry
- Check for typos in `.env` version variables

### Debugging Locally

Use the helper scripts to debug issues:

```bash
# Test a single service
./.github/scripts/test-service.sh metabase

# Test without cleanup (to inspect containers)
./.github/scripts/test-service.sh metabase --no-cleanup

# Extract all images
./.github/scripts/extract-images.sh

# Full Docker cleanup
./.github/scripts/docker-cleanup.sh --full
```

### Getting Container Logs

If a service fails in CI:

1. Download the `docker-compose-test-results` artifact
2. Open `<service>-logs.txt`
3. Look for error messages, stack traces, or startup failures

---

## Manual Workflow Triggers

The pipeline supports manual triggering with options:

### Options

| Input | Description | Default |
|-------|-------------|---------|
| `skip_cve_scan` | Skip vulnerability scanning | `false` |
| `specific_service` | Test only one service | (empty = all) |
| `fail_on_high` | Fail on HIGH severity CVEs | `false` |

### How to Trigger

1. Go to **Actions** > **CI/CD Pipeline**
2. Click **Run workflow**
3. Select branch and fill in options
4. Click **Run workflow**

### Example Use Cases

- **Quick test of a single service**: Set `specific_service` to the service name
- **Faster iteration without CVE scan**: Set `skip_cve_scan` to `true`
- **Security audit mode**: Set `fail_on_high` to `true`

---

## Performance Considerations

### Concurrency Controls

All workflows include concurrency controls to prevent resource conflicts and redundant runs:

| Workflow | Concurrency Group | Behavior |
|----------|------------------|----------|
| CI/CD Pipeline | `ci-cd-${{ github.ref }}` | Cancels in-progress runs on same branch |
| Publish OCI | `publish-oci-${{ github.ref }}` | Waits for previous run to complete |
| Check Versions | `check-versions` | Cancels in-progress runs |

**Why different behaviors?**
- **CI/CD**: Cancel-in-progress for faster feedback on new commits
- **Publish OCI**: Wait (no cancel) to ensure all artifacts are published
- **Check Versions**: Cancel-in-progress since only latest check matters

### Expected Durations

| Phase | Duration | Notes |
|-------|----------|-------|
| Discover | ~30s | Fast, just file scanning |
| Extract Images | ~1m | Parses all compose files |
| CVE Scan | ~10-15m | Depends on image count |
| Test Services | ~15-25m | Sequential, 30+ services |
| **Total** | **~30m** | Meets the <30 minute goal |

### Optimizations Applied

1. **Batch image scanning**: Each unique image is scanned only once
2. **Aggressive cleanup**: Images removed after scanning and testing
3. **Sequential testing**: Prevents resource contention
4. **Parallel job execution**: Independent jobs run concurrently where possible

### Disk Space Management

GitHub Actions runners have ~14GB of disk space. The pipeline manages this by:

- Removing each image immediately after CVE scanning
- Removing all images, volumes, and containers after each service test
- Running `docker system prune -af` between services

---

## Artifacts Reference

### `cve-scan-results`

Contains:
- `summary.md`: Overview of all scan results
- `<image-name>.json`: Full Trivy output per image

### `docker-compose-test-results`

Contains:
- `summary.md`: Test results overview
- `<service>-logs.txt`: Container logs (only for failed tests)

---

## Support

For issues with the CI/CD pipeline:

1. Check this documentation first
2. Review the troubleshooting section
3. Check workflow run logs in GitHub Actions
4. Open an issue if the problem persists
