# MinIO

> **OCI Artifact** - Deploy directly from GitHub Container Registry

MinIO is a high-performance, S3-compatible object storage system designed for large-scale data infrastructure, AI/ML workloads, and cloud-native applications.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

### Using bc CLI (Recommended)

```bash
# 1. Create environment file
cat > .env.minio << 'EOF'
COMPOSE_PROJECT_NAME=minio
SERVICE_DOMAIN=minio.example.com
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=Swordfish
EOF

# 2. Deploy
bc minio up

# 3. Check status
bc minio ps
```

> **Note:** Install the bc CLI with: `curl -fsSL https://raw.githubusercontent.com/beevelop/beecompose/main/scripts/install.sh | sudo bash`

### Manual Deployment

```bash
# 1. Create environment file
cat > .env.minio << 'EOF'
COMPOSE_PROJECT_NAME=minio
SERVICE_DOMAIN=minio.example.com
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=Swordfish
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/minio:latest --env-file .env.minio up -d --pull always

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/minio:latest --env-file .env.minio ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| minio | minio/minio | MinIO object storage server |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for MinIO API access | `minio.example.com` |
| `MINIO_ROOT_USER` | MinIO root username | `admin` |
| `MINIO_ROOT_PASSWORD` | MinIO root password (min 8 characters) | `Swordfish` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `minio` |
| `MINIO_VERSION` | MinIO image tag | `RELEASE.2025-01-20T14-49-07Z` |

## Volumes

| Volume | Purpose |
|--------|---------|
| `minio_data` | Object storage data |
| `minio_config` | MinIO configuration |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 9000 | HTTP | S3-compatible API (via Traefik) |
| 9001 | HTTP | Web console (internal) |

**Note**: The S3 API (port 9000) is exposed via Traefik. The web console (port 9001) is not exposed by default. To access the console, add additional Traefik labels or use port forwarding.

## Post-Deployment

1. **Access MinIO**: Navigate to `https://minio.example.com` (API endpoint)
2. **Console Access**: To access the web console, you'll need to configure additional routing for port 9001
3. **Create Buckets**: Use the `mc` CLI or console to create buckets
4. **Access Keys**: Generate access keys for your applications
5. **Configure Clients**: Use the S3-compatible endpoint in your applications

### Using MinIO Client (mc)

```bash
# Install mc
brew install minio/stable/mc  # macOS
# or download from https://min.io/download

# Configure alias
mc alias set myminio https://minio.example.com admin Swordfish

# Create bucket
mc mb myminio/my-bucket

# List buckets
mc ls myminio
```

## Common Operations

### Using bc CLI

```bash
bc minio logs -f     # View logs
bc minio restart     # Restart
bc minio down        # Stop
bc minio update      # Pull and recreate
```

### Using docker compose directly

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/minio:latest --env-file .env.minio"

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

### MinIO not starting
Ensure `MINIO_ROOT_PASSWORD` is at least 8 characters long. Check logs with `docker logs minio`.

### Cannot access via S3 clients
Verify your client is configured with the correct endpoint URL, access key, and secret key. Ensure SSL/TLS is enabled if using HTTPS.

### Permission denied errors
Check that the `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` match your client configuration.

### Container not healthy
Check logs with `dc logs minio` and ensure all required environment variables are set.

## Links

- [Official Documentation](https://min.io/docs/minio/linux/index.html)
- [Docker Hub](https://hub.docker.com/r/minio/minio)
- [GitHub](https://github.com/minio/minio)
