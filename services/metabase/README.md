# Metabase

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Metabase is an open-source business intelligence tool that lets you create charts and dashboards using data from various databases without writing SQL.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=metabase
SERVICE_DOMAIN=metabase.example.com
DB_USER=metabase
DB_NAME=metabase
DB_PASS=Swordfish
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/metabase:latest --env-file .env up -d

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/metabase:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| metabase | metabase/metabase | Metabase BI application |
| metabase-postgres | postgres:17-alpine | PostgreSQL database for Metabase metadata |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Metabase access | `metabase.example.com` |
| `DB_USER` | PostgreSQL username | `metabase` |
| `DB_PASS` | PostgreSQL password | `Swordfish` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `metabase` |
| `DB_NAME` | PostgreSQL database name | `metabase` |
| `METABASE_VERSION` | Metabase image tag | `v0.58.2` |
| `POSTGRES_TAG` | PostgreSQL image tag | `17-alpine` |

## Volumes

| Volume | Purpose |
|--------|---------|
| `metabase_postgres_data` | PostgreSQL database files (stores Metabase configuration) |

## Post-Deployment

1. **Access Metabase**: Navigate to `https://metabase.example.com`
2. **Setup Wizard**: Complete the initial setup wizard
3. **Admin Account**: Create your first admin user
4. **Add Database**: Connect to your data sources (MySQL, PostgreSQL, etc.)
5. **Create Questions**: Start building queries and visualizations
6. **Build Dashboards**: Combine questions into dashboards

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/metabase:latest --env-file .env"

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

### Metabase slow to start
Metabase has a `start_period` of 60 seconds. Initial startup includes database migrations which can take time.

### Cannot connect to data sources
Ensure the target database is accessible from the Metabase container. You may need to add the database to the same Docker network.

### Memory issues
Metabase runs on the JVM. If you experience out-of-memory issues, consider limiting queries or increasing container resources.

### Container not healthy
Check logs with `dc logs metabase` and ensure all required environment variables are set.

## Links

- [Official Documentation](https://www.metabase.com/docs/latest/)
- [Docker Hub](https://hub.docker.com/r/metabase/metabase)
- [GitHub](https://github.com/metabase/metabase)
