# CI/CD Pipeline Documentation

This document describes the GitHub Actions CI/CD pipeline for BeeCompose, including how to use it, interpret results, and troubleshoot common issues.

## Table of Contents

1. [Overview](#overview)
2. [Pipeline Architecture](#pipeline-architecture)
3. [Adding New Services](#adding-new-services)
4. [Interpreting Results](#interpreting-results)
5. [CVE Scanning Policy](#cve-scanning-policy)
6. [Troubleshooting](#troubleshooting)
7. [Manual Workflow Triggers](#manual-workflow-triggers)
8. [Performance Considerations](#performance-considerations)

---

## Overview

The CI/CD pipeline automatically validates all Docker Compose configurations and scans container images for security vulnerabilities on every push and pull request.

### Key Features

- **Sequential Testing**: All 30+ services are tested one after another to prevent resource conflicts
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

### Jobs Overview

```
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

#### 1. Discover Services
- Finds all `docker-compose.yml` files under `services/`
- Validates YAML syntax using `docker compose config`
- Outputs list of services for subsequent jobs

#### 2. Extract Images
- Parses each compose file to extract image references
- Resolves environment variables from `.env` and `.env.example`
- Deduplicates images (many services share postgres, redis, etc.)

#### 3. CVE Scan
- Installs Trivy vulnerability scanner
- Scans each unique image once
- Reports vulnerability counts by severity
- **Fails pipeline if CRITICAL vulnerabilities found**
- Cleans up images after scanning to save disk space

#### 4. Test Services
- Tests each service sequentially:
  1. Load environment variables
  2. Pull images
  3. Start containers with `docker compose up -d`
  4. Wait for services to stabilize
  5. Verify containers are running (not in restart loop)
  6. Capture logs for failed tests
  7. **Aggressive cleanup**: remove containers, volumes, AND images
- Reports pass/fail for each service

#### 5. Summary
- Generates GitHub Step Summary with overall results
- Reports metrics (services tested, images scanned, CVE counts)

---

## Adding New Services

When adding a new service to BeeCompose, ensure it works with the CI/CD pipeline:

### Requirements

1. **Directory Structure**
   ```
   services/<service-name>/
   ├── docker-compose.yml    # Required
   ├── .env                  # Required (image versions)
   ├── .env.example          # Recommended (example config)
   └── bee                   # Optional (service script)
   ```

2. **Environment Variables**
   - Use `${VAR}` substitution in compose files
   - Define version tags in `.env` (committed)
   - Provide example values in `.env.example` (committed)

3. **Compose File Standards**
   ```yaml
   version: "3"
   services:
     myservice:
       image: myimage:${MYSERVICE_VERSION}
       restart: unless-stopped
       logging:
         driver: "json-file"
         options:
           max-size: "500k"
           max-file: "50"
       # ... other config
   
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

# Test with the helper script
./.github/scripts/test-service.sh <service-name>
```

### Pipeline Considerations

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

- **CRITICAL**: Blocks pipeline (must fix before merging)
- **HIGH**: Warning (consider updating)
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
| CRITICAL | **Block** pipeline (must fix) |
| HIGH | Warning only (logged in report) |
| MEDIUM | Informational |
| LOW | Informational |

### Enabling Stricter Policy

To fail on HIGH vulnerabilities, use manual workflow dispatch:

1. Go to **Actions** > **CI/CD Pipeline**
2. Click **Run workflow**
3. Set `fail_on_high` to `true`

Or request a team decision to change the default in the workflow file.

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
