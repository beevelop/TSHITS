# Bitwarden (Vaultwarden)

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Self-hosted password manager using Vaultwarden, a lightweight Bitwarden-compatible server written in Rust.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=bitwarden
SERVICE_DOMAIN=bitwarden.example.com
ADMIN_TOKEN=your_secure_admin_token_here
SMTP_HOST=smtp.example.com
SMTP_FROM=noreply@example.com
SMTP_PORT=465
SMTP_SECURITY=force_tls
SMTP_USERNAME=noreply@example.com
SMTP_PASSWORD=Swordfish
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/bitwarden:latest --env-file .env up -d

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/bitwarden:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| bitwarden | vaultwarden/server | Password vault server |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Bitwarden access | `bitwarden.example.com` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `bitwarden` |
| `ADMIN_TOKEN` | Admin panel access token (leave empty to disable) | _(empty)_ |
| `SMTP_HOST` | SMTP server hostname | _(empty)_ |
| `SMTP_FROM` | Email sender address | _(empty)_ |
| `SMTP_PORT` | SMTP server port | `587` |
| `SMTP_SECURITY` | SMTP security (`starttls`, `force_tls`, `off`) | `starttls` |
| `SMTP_USERNAME` | SMTP authentication username | _(empty)_ |
| `SMTP_PASSWORD` | SMTP authentication password | _(empty)_ |

### Hardcoded Settings

| Setting | Value | Description |
|---------|-------|-------------|
| `SIGNUPS_ALLOWED` | `false` | New user registrations disabled |
| `SHOW_PASSWORD_HINT` | `false` | Password hints hidden |

## Volumes

| Volume | Purpose |
|--------|---------|
| `bitwarden_data` | Vault data, attachments, and SQLite database |

## Post-Deployment

1. **Access the web vault** at `https://bitwarden.example.com`

2. **Enable admin panel** (optional):
   - Generate a secure token: `openssl rand -base64 48`
   - Set `ADMIN_TOKEN` in your environment file
   - Access admin panel at `https://bitwarden.example.com/admin`

3. **Create first user**:
   - Since signups are disabled, use the admin panel to invite users
   - Or temporarily enable signups via admin panel

4. **Configure email** (recommended):
   - Set all `SMTP_*` variables for email verification and 2FA

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/bitwarden:latest --env-file .env"

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

### Admin panel not accessible
Ensure `ADMIN_TOKEN` is set. An empty token disables the admin panel entirely.

### Emails not sending
Verify SMTP settings. Test with `SMTP_SECURITY=starttls` first, then try `force_tls` for port 465.

### Container not healthy
Check logs with `dc logs bitwarden` and ensure the domain is correctly configured.

## Links

- [Vaultwarden Documentation](https://github.com/dani-garcia/vaultwarden/wiki)
- [Vaultwarden on Docker Hub](https://hub.docker.com/r/vaultwarden/server)
- [Vaultwarden GitHub](https://github.com/dani-garcia/vaultwarden)
- [Bitwarden Help Center](https://bitwarden.com/help/)
