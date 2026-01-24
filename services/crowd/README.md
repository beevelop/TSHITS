# Crowd

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Atlassian Crowd - centralized identity management for single sign-on (SSO) and user directory management across Atlassian and third-party applications.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

### Using bc CLI (Recommended)

```bash
# 1. Create environment file
cat > .env.crowd << 'EOF'
COMPOSE_PROJECT_NAME=crowd
SERVICE_DOMAIN=crowd.example.com
POSTGRES_PASS=Swordfish
EOF

# 2. Deploy
bc crowd up

# 3. Check status
bc crowd ps
```

> **Note:** Install the bc CLI with: `curl -fsSL https://raw.githubusercontent.com/beevelop/beecompose/main/scripts/install.sh | sudo bash`

### Manual Deployment

```bash
# 1. Create environment file
cat > .env.crowd << 'EOF'
COMPOSE_PROJECT_NAME=crowd
SERVICE_DOMAIN=crowd.example.com
POSTGRES_PASS=Swordfish
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/crowd:latest --env-file .env.crowd up -d --pull always

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/crowd:latest --env-file .env.crowd ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))
- Atlassian Crowd license (commercial or evaluation)

## Dependencies

This service includes all required backing stores:

| Dependency | Container | Purpose |
|------------|-----------|---------|
| PostgreSQL | crowd-postgres | Identity data storage |

See [Service Dependency Graph](../../docs/DEPENDENCIES.md) for details.

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| crowd | atlassian/crowd | Crowd application server |
| crowd-postgres | postgres | PostgreSQL database |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Crowd access | `crowd.example.com` |
| `POSTGRES_PASS` | PostgreSQL password | `Swordfish` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `crowd` |
| `POSTGRES_USER` | PostgreSQL username | `crowd` |
| `POSTGRES_DB` | PostgreSQL database name | `crowd` |

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
| `crowd_data` | Crowd home directory (configuration, plugins, caches) |
| `postgres_data` | PostgreSQL database storage |

## Post-Deployment

1. **Wait for startup** - Crowd takes 1-2 minutes to initialize

2. **Access setup wizard** at `https://crowd.example.com/crowd`

3. **Enter license key**:
   - Obtain from [my.atlassian.com](https://my.atlassian.com)
   - Select "Crowd Server" license

4. **Configure database**:
   - Select "JDBC Connection"
   - Database type: PostgreSQL
   - JDBC URL: `jdbc:postgresql://postgresql:5432/crowd`
   - Username: `crowd` (or your `POSTGRES_USER`)
   - Password: your `POSTGRES_PASS` value

5. **Set base URL**:
   - Ensure it matches `https://${SERVICE_DOMAIN}/crowd`

6. **Create admin account**:
   - Set up the initial Crowd administrator

7. **Configure applications**:
   - Add applications (Jira, Confluence, etc.) that will use Crowd for SSO
   - Configure user directories (internal, LDAP, Active Directory)

## Common Operations

### Using bc CLI

```bash
bc crowd logs -f        # View logs
bc crowd logs -f crowd  # View Crowd logs only
bc crowd restart        # Restart
bc crowd down           # Stop
bc crowd update         # Pull and recreate
```

### Using docker compose directly

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/crowd:latest --env-file .env.crowd"

# View logs
dc logs -f

# View Crowd logs only
dc logs -f crowd

# Restart
dc restart

# Stop
dc down

# Update
dc pull && dc up -d

# Backup database
docker exec crowd-postgres pg_dump -U crowd crowd > backup.sql
```

## Troubleshooting

### Cannot connect to database during setup
Use the internal Docker network hostname `postgresql` (not `localhost` or `crowd-postgres`). The JDBC URL should be `jdbc:postgresql://postgresql:5432/crowd`.

### SSO not working across applications
Ensure all applications are configured with the same Crowd SSO cookie domain. The cookie domain should be set to `.example.com` for subdomains to share authentication.

### Application authentication failing
Verify the application password in Crowd matches what's configured in the connecting application (Jira, Confluence, etc.).

### Slow startup
Crowd requires 1-2 minutes for initial startup. Check health status and wait for the container to become healthy.

### Container not healthy
Check logs with `dc logs crowd` and ensure all required environment variables are set. The health check has a 120s start period.

## Links

- [Crowd Documentation](https://confluence.atlassian.com/crowd/crowd-documentation-home-141996780.html)
- [Crowd on Docker Hub](https://hub.docker.com/r/atlassian/crowd)
- [Atlassian Support](https://support.atlassian.com/crowd/)
