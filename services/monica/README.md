# Monica

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Monica is an open-source personal relationship management (PRM) system that helps you organize interactions with your loved ones, family, and friends.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=monica
SERVICE_DOMAIN=monica.example.com
DB_NAME=monica
DB_USER=monica
DB_PASS=Swordfish
DB_ROOT_PASS=Swordfish
EOF

# 2. Create monica.env with application settings
cat > monica.env << 'EOF'
APP_ENV=production
APP_DEBUG=false
APP_KEY=your32characterlongapplicationkey
DB_CONNECTION=mysql
DB_PORT=3306
MAIL_DRIVER=smtp
MAIL_HOST=smtp.example.com
MAIL_PORT=587
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=monica@example.com
MAIL_FROM_NAME=Monica
APP_DEFAULT_TIMEZONE=UTC
APP_DISABLE_SIGNUP=true
CHECK_VERSION=true
CACHE_DRIVER=database
SESSION_DRIVER=file
QUEUE_DRIVER=sync
DEFAULT_FILESYSTEM=public
2FA_ENABLED=true
EOF

# 3. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/monica:latest --env-file .env up -d

# 4. Check status
docker compose -f oci://ghcr.io/beevelop/monica:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| monica | monica:5.0.0-beta.5-apache | Monica PRM application |
| monica-mysql | mysql:8.0 | MySQL database |

## Environment Variables

### Required (.env)

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Monica access | `monica.example.com` |
| `DB_USER` | MySQL username | `monica` |
| `DB_PASS` | MySQL password | `Swordfish` |
| `DB_ROOT_PASS` | MySQL root password | `Swordfish` |

### Optional (.env)

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `monica` |
| `DB_NAME` | MySQL database name | `monica` |
| `MONICA_VERSION` | Monica image tag | `5.0.0-beta.5-apache` |
| `MYSQL_TAG` | MySQL image tag | `8.0` |

### Application Settings (monica.env)

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_ENV` | Environment (local/production) | `production` |
| `APP_DEBUG` | Enable debug mode | `false` |
| `APP_KEY` | 32-character encryption key | Required |
| `APP_DEFAULT_TIMEZONE` | Default timezone for new users | `UTC` |
| `APP_DISABLE_SIGNUP` | Disable public registration | `true` |
| `MAIL_DRIVER` | Mail driver (smtp/sendmail/log) | `smtp` |
| `MAIL_HOST` | SMTP server hostname | - |
| `MAIL_PORT` | SMTP server port | `587` |
| `MAIL_USERNAME` | SMTP username | - |
| `MAIL_PASSWORD` | SMTP password | - |
| `MAIL_ENCRYPTION` | SMTP encryption (tls/ssl/null) | `tls` |
| `CHECK_VERSION` | Check for updates | `true` |
| `2FA_ENABLED` | Enable two-factor authentication | `true` |
| `DEFAULT_FILESYSTEM` | File storage (public/s3) | `public` |

## Volumes

| Volume | Purpose |
|--------|---------|
| `monica_mysql_data` | MySQL database files |

## Post-Deployment

1. **Generate APP_KEY**: Create a 32-character random key:
   ```bash
   cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
   ```
2. **Update monica.env**: Add the generated key to `APP_KEY`
3. **Access Monica**: Navigate to `https://monica.example.com`
4. **Create Account**: Register your first user (disable signups after in monica.env)
5. **Configure Mail**: Set up SMTP for reminders and notifications
6. **Set Timezone**: Configure your preferred timezone

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/monica:latest --env-file .env"

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

### Monica not starting
Monica has a `start_period` of 60 seconds. Check logs with `docker logs monica`.

### Database connection errors
Ensure MySQL is healthy: `docker logs monica-mysql`. The MySQL container has a 30-second start period.

### Missing APP_KEY error
Generate a 32-character key and add it to monica.env. The key is required for encryption.

### Emails not sending
Verify SMTP settings in monica.env. Test with `MAIL_DRIVER=log` to debug without sending actual emails.

### Container not healthy
Check logs with `dc logs monica` and ensure all required environment variables are set.

## Links

- [Official Documentation](https://www.monicahq.com/docs)
- [Docker Hub](https://hub.docker.com/_/monica)
- [GitHub](https://github.com/monicahq/monica)
