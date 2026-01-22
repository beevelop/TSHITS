# Statping-ng

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Open-source status page and monitoring solution for websites and applications with a beautiful interface and comprehensive alerting.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=statping
SERVICE_DOMAIN=status.example.com
DB_PASS=Swordfish
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/statping:latest --env-file .env up -d

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/statping:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))

## Dependencies

This service includes all required backing stores:

| Dependency | Container | Purpose |
|------------|-----------|---------|
| PostgreSQL | statping-postgres | Status and metrics storage |

See [Service Dependency Graph](../../docs/DEPENDENCIES.md) for details.

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| statping | adamboutcher/statping-ng:v0.90.78 | Status page web application |
| statping-postgres | postgres:17-alpine | PostgreSQL database |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for the status page | `status.example.com` |
| `DB_PASS` | PostgreSQL password | `Swordfish` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `statping` |
| `DB_NAME` | PostgreSQL database name | `statping` |
| `DB_USER` | PostgreSQL username | `statping` |

## Volumes

| Volume | Purpose |
|--------|---------|
| `statping_postgres_data` | PostgreSQL database files |
| `statping_app_data` | Statping application data |

## Post-Deployment

1. Access the status page at `https://status.example.com`
2. Complete the initial setup wizard
3. Create your first service to monitor
4. Configure notification channels (Slack, Email, Discord, etc.)
5. Customize the public status page theme

### Default Setup

On first launch, Statping will guide you through:
- Creating an admin account
- Setting up your first monitored service
- Configuring the public status page

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/statping:latest --env-file .env"

# View logs
dc logs -f

# Restart
dc restart

# Stop
dc down

# Update
dc pull && dc up -d
```

## Troubleshooting

### Database connection errors
Ensure PostgreSQL is healthy before Statping starts. Check with:
```bash
dc logs statping-postgres
```

### Container not healthy
Check logs with `dc logs statping` and ensure all required environment variables are set.

### Services showing incorrect status
Verify network connectivity from the container and check timeout settings for each monitored service.

## Links

- [Official Documentation](https://github.com/statping-ng/statping-ng)
- [Docker Hub](https://hub.docker.com/r/adamboutcher/statping-ng)
- [GitHub](https://github.com/statping-ng/statping-ng)
