# Confluence

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Atlassian Confluence - team collaboration and wiki software for creating, organizing, and sharing knowledge.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=confluence
SERVICE_DOMAIN=confluence.example.com
POSTGRES_PASS=Swordfish
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/confluence:latest --env-file .env up -d

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/confluence:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))
- Atlassian Confluence license (commercial or evaluation)
- Minimum 4GB RAM recommended

## Dependencies

This service includes all required backing stores:

| Dependency | Container | Purpose |
|------------|-----------|---------|
| PostgreSQL | confluence-postgres | Wiki data storage |

See [Service Dependency Graph](../../docs/DEPENDENCIES.md) for details.

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| confluence | atlassian/confluence | Confluence application server |
| confluence-postgres | postgres | PostgreSQL database |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Confluence access | `confluence.example.com` |
| `POSTGRES_PASS` | PostgreSQL password | `Swordfish` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `confluence` |
| `POSTGRES_USER` | PostgreSQL username | `confluence` |
| `POSTGRES_DB` | PostgreSQL database name | `confluence` |
| `JVM_MINIMUM_MEMORY` | JVM minimum heap size | `1024m` |
| `JVM_MAXIMUM_MEMORY` | JVM maximum heap size | `2048m` |

### Proxy Settings (Automatic)

These are configured automatically based on `SERVICE_DOMAIN`:

| Setting | Value | Description |
|---------|-------|-------------|
| `ATL_PROXY_NAME` | `${SERVICE_DOMAIN}` | Proxy hostname |
| `ATL_PROXY_PORT` | `443` | Proxy port (HTTPS) |
| `ATL_TOMCAT_SCHEME` | `https` | URL scheme |
| `ATL_TOMCAT_SECURE` | `true` | Secure connection flag |

## Volumes

| Volume | Purpose |
|--------|---------|
| `confluence_data` | Confluence home directory (attachments, config, plugins) |
| `postgres_data` | PostgreSQL database storage |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8091 | TCP | Synchrony (collaborative editing) |

## Post-Deployment

1. **Wait for startup** - Confluence takes 2-3 minutes to initialize on first run

2. **Access setup wizard** at `https://confluence.example.com`

3. **Enter license key**:
   - Obtain from [my.atlassian.com](https://my.atlassian.com)
   - Select "Production" or "Evaluation" license

4. **Configure database** (already done):
   - Database type: PostgreSQL
   - Connection is pre-configured via environment variables

5. **Create admin account**:
   - Set up the initial administrator user
   - Configure base URL (should match `SERVICE_DOMAIN`)

6. **Configure Synchrony** (collaborative editing):
   - Synchrony runs on port 8091 by default
   - For advanced setups, configure Synchrony proxy settings

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/confluence:latest --env-file .env"

# View logs
dc logs -f

# View Confluence logs only
dc logs -f confluence

# Restart
dc restart

# Stop
dc down

# Update
dc pull && dc up -d

# Backup database
docker exec confluence-postgres pg_dump -U confluence confluence > backup.sql
```

## Troubleshooting

### Confluence slow to start
Confluence requires significant startup time (2-5 minutes). Check health status and wait for the container to become healthy.

### Out of memory errors
Increase `JVM_MAXIMUM_MEMORY`. For production, 4GB+ is recommended:
```bash
JVM_MAXIMUM_MEMORY=4096m
```

### Database connection failed
Verify PostgreSQL is healthy: `dc logs confluence-postgres`. Ensure credentials match in both services.

### Collaborative editing not working
Check that port 8091 is accessible. Synchrony logs can be found in the Confluence container logs.

### Container not healthy
Check logs with `dc logs confluence` and ensure all required environment variables are set. Note the long `start_period` (180s) for health checks.

## Links

- [Confluence Documentation](https://confluence.atlassian.com/doc/confluence-documentation-home-135922.html)
- [Confluence on Docker Hub](https://hub.docker.com/r/atlassian/confluence)
- [Atlassian Support](https://support.atlassian.com/confluence-cloud/)
