# Huginn

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Huginn is a system for building agents that perform automated tasks for you online. It can read the web, watch for events, and take actions on your behalf. Think of it as a hackable IFTTT or Zapier running on your own server.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=huginn
SERVICE_DOMAIN=huginn.example.com
DB_PASS=Swordfish
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/huginn:latest --env-file .env up -d

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/huginn:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))

## Dependencies

This service includes all required backing stores:

| Dependency | Container | Purpose |
|------------|-----------|---------|
| PostgreSQL | huginn-postgres | Agent data storage |

See [Service Dependency Graph](../../docs/DEPENDENCIES.md) for details.

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| huginn | ghcr.io/huginn/huginn:latest | Automation platform and web interface |
| huginn-postgres | postgres:17-alpine | PostgreSQL database backend |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Traefik routing | `huginn.example.com` |
| `DB_PASS` | PostgreSQL database password | `Swordfish` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `huginn` |
| `DB_USER` | PostgreSQL database user | `huginn` |
| `DB_NAME` | PostgreSQL database name | `huginn` |
| `INVITATION_CODE` | Code required for new user registration | - (empty = open registration) |

## Volumes

| Volume | Purpose |
|--------|---------|
| `postgres_data` | PostgreSQL database persistence |

## Post-Deployment

1. **Access the UI**: Navigate to `https://huginn.example.com`
2. **Login with defaults**: 
   - Username: `admin`
   - Password: `password`
3. **Change admin password**: Go to Account → Edit Account immediately after login
4. **Create your first agent**: Click "New Agent" and choose from available types:
   - **Website Agent**: Monitor websites for changes
   - **RSS Agent**: Parse RSS/Atom feeds
   - **Webhook Agent**: Receive webhooks from external services
   - **Email Agent**: Send email notifications
   - **Trigger Agent**: React to events based on conditions
5. **Build agent scenarios**: Chain agents together to create automation workflows
6. **Set invitation code**: Configure `INVITATION_CODE` to control user registration

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/huginn:latest --env-file .env"

# View logs
dc logs -f

# Restart
dc restart

# Stop
dc down

# Update
dc pull && dc up -d

# Access Rails console
docker exec -it huginn bash -c "bundle exec rails console"

# Run background jobs manually
docker exec -it huginn bash -c "bundle exec rails runner 'Agent.receive!'"
```

## Example Agents

### Monitor a website for changes
1. Create a **Website Agent** with:
   - URL: `https://example.com/page-to-monitor`
   - Mode: `on_change`
   - Extract: CSS selectors for content

### Get RSS feed updates
1. Create an **RSS Agent** with:
   - URL: `https://example.com/feed.xml`
   - Expected update period: `1 day`

### Send notifications
1. Create an **Email Agent** or **Pushover Agent** that receives events from other agents

## Troubleshooting

### Background jobs not running
Huginn runs background jobs automatically. Check the delayed job worker:
```bash
docker exec -it huginn bash -c "ps aux | grep delayed"
```

### Agents not checking on schedule
Verify the system clock is correct and check agent logs in the web interface.

### Database connection errors
Ensure PostgreSQL is healthy before Huginn starts:
```bash
dc logs huginn-postgres
```

### Container not healthy
Check logs with `dc logs huginn` and ensure all required environment variables are set.

## Links

- [Official Documentation](https://github.com/huginn/huginn/wiki)
- [GitHub Container Registry](https://github.com/huginn/huginn/pkgs/container/huginn)
- [GitHub](https://github.com/huginn/huginn)
