# Nexus Repository Manager

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Sonatype Nexus Repository Manager is a universal artifact repository that supports Maven, npm, Docker, PyPI, and many other package formats. This stack provides a production-ready Nexus 3 instance with Traefik integration.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=nexus
SERVICE_DOMAIN=nexus.example.com
NEXUS_VERSION=3.88.0-alpine
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/nexus:latest --env-file .env up -d

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/nexus:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| nexus | sonatype/nexus3:3.88.0-alpine | Nexus Repository Manager |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Traefik routing | `nexus.example.com` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `nexus` |
| `NEXUS_VERSION` | Nexus image version | `3.88.0-alpine` |

## Volumes

| Volume | Purpose |
|--------|---------|
| `nexus_data` | Nexus data, blobs, and configuration (`/nexus-data`) |

## Post-Deployment

### Initial Admin Password

On first startup, Nexus generates a random admin password:

```bash
# Retrieve initial admin password
docker exec nexus cat /nexus-data/admin.password
```

### First Login

1. Navigate to `https://nexus.example.com`
2. Click "Sign In" in the top right
3. Login with username `admin` and the password from above
4. Complete the setup wizard to set a new password and configure anonymous access

### Configure Repositories

Common repository configurations:
- **Maven**: Create hosted, proxy (Maven Central), and group repositories
- **npm**: Create proxy to npmjs.org
- **Docker**: Create hosted registry and configure Docker client

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/nexus:latest --env-file .env"

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

### Slow startup
Nexus can take 2-3 minutes to start. The healthcheck has a 120-second start period to accommodate this.

### Out of memory
Nexus requires significant memory. Consider adding memory limits or increasing host RAM if experiencing OOM issues.

### Container not healthy
Check logs with `dc logs nexus` and ensure all required environment variables are set.

## Links

- [Official Documentation](https://help.sonatype.com/repomanager3)
- [Docker Hub](https://hub.docker.com/r/sonatype/nexus3)
- [GitHub](https://github.com/sonatype/nexus-public)
