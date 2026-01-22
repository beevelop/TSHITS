# Cabot

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Self-hosted monitoring and alerting platform that checks services and sends alerts via email, SMS, or chat integrations.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=cabot
SERVICE_DOMAIN=cabot.example.com
ADMIN_EMAIL=admin@example.com
CABOT_FROM_EMAIL=cabot@example.com
EMAIL_HOST=smtp.example.com
EMAIL_USER=noreply@example.com
EMAIL_PASSWORD=Swordfish
EMAIL_PORT=465
EMAIL_USE_TLS=1
DJANGO_SECRET_KEY=your_secure_random_secret_key_here
WWW_HTTP_HOST=cabot.example.com
WWW_SCHEME=https
CABOT_VERSION=0.11.16
POSTGRES_TAG=17-alpine
RABBITMQ_TAG=3.13-alpine
CABOT_PLUGINS_ENABLED=cabot_alert_twilio,cabot_alert_email,cabot_alert_slack
DJANGO_SETTINGS_MODULE=cabot.settings
DATABASE_URL=postgres://postgres@postgres:5432/postgres
CELERY_BROKER_URL=amqp://guest:guest@rabbitmq:5672//
LOG_FILE=/dev/null
HTTP_USER_AGENT=Cabot
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/cabot:latest --env-file .env up -d

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/cabot:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))

## Dependencies

This service includes all required backing stores:

| Dependency | Container | Purpose |
|------------|-----------|---------|
| PostgreSQL | cabot-postgres | Primary database |
| RabbitMQ | cabot-rabbitmq | Celery message broker |

See [Service Dependency Graph](../../docs/DEPENDENCIES.md) for details.

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| cabot-web | cabotapp/cabot | Web interface and API |
| cabot-worker | cabotapp/cabot | Celery worker for background tasks |
| cabot-beat | cabotapp/cabot | Celery beat for scheduled checks |
| cabot-postgres | postgres | PostgreSQL database |
| cabot-rabbitmq | rabbitmq | Message broker for Celery |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Cabot access | `cabot.example.com` |
| `ADMIN_EMAIL` | Admin notification email | `admin@example.com` |
| `CABOT_FROM_EMAIL` | Alert sender email address | `cabot@example.com` |
| `DJANGO_SECRET_KEY` | Django secret key (generate securely) | `your_random_key` |
| `WWW_HTTP_HOST` | Public hostname | `cabot.example.com` |
| `DATABASE_URL` | PostgreSQL connection string | `postgres://postgres@postgres:5432/postgres` |
| `CELERY_BROKER_URL` | RabbitMQ connection string | `amqp://guest:guest@rabbitmq:5672//` |

### Email Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `EMAIL_HOST` | SMTP server hostname | `smtp.example.com` |
| `EMAIL_USER` | SMTP username | `noreply@example.com` |
| `EMAIL_PASSWORD` | SMTP password | `Swordfish` |
| `EMAIL_PORT` | SMTP port | `465` |
| `EMAIL_USE_TLS` | Enable TLS (`1` or `0`) | `1` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `cabot` |
| `WWW_SCHEME` | URL scheme | `https` |
| `CABOT_PLUGINS_ENABLED` | Enabled alert plugins | `cabot_alert_twilio,cabot_alert_email,cabot_alert_slack` |
| `DJANGO_SETTINGS_MODULE` | Django settings module | `cabot.settings` |
| `LOG_FILE` | Log file path | `/dev/null` |
| `HTTP_USER_AGENT` | User agent for HTTP checks | `Cabot` |

### Optional Integrations

| Variable | Description |
|----------|-------------|
| `CALENDAR_ICAL_URL` | iCal URL for on-call rotation sync |
| `GRAPHITE_API` | Graphite server URL |
| `GRAPHITE_USER` | Graphite username |
| `GRAPHITE_PASS` | Graphite password |
| `GRAPHITE_FROM` | Graphite time range (default: `-10minute`) |
| `HIPCHAT_ALERT_ROOM` | HipChat room name/ID |
| `HIPCHAT_API_KEY` | HipChat API key |
| `JENKINS_API` | Jenkins server URL |
| `JENKINS_USER` | Jenkins username |
| `JENKINS_PASS` | Jenkins password |
| `TWILIO_ACCOUNT_SID` | Twilio account SID |
| `TWILIO_AUTH_TOKEN` | Twilio auth token |
| `TWILIO_OUTGOING_NUMBER` | Twilio phone number |
| `AUTH_LDAP` | Enable LDAP auth (`true`/`false`) |
| `AUTH_LDAP_SERVER_URI` | LDAP server URI |
| `AUTH_LDAP_BIND_DN` | LDAP bind DN |
| `AUTH_LDAP_BIND_PASSWORD` | LDAP bind password |
| `AUTH_LDAP_USER_SEARCH` | LDAP user search base |

## Volumes

| Volume | Purpose |
|--------|---------|
| `postgres_data` | PostgreSQL database storage |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 5000 | HTTP | Web interface (also via Traefik) |

## Post-Deployment

1. **Access Cabot** at `https://cabot.example.com`

2. **Create admin user**:
   ```bash
   docker exec -it cabot-web python manage.py createsuperuser
   ```

3. **Configure services**:
   - Add services to monitor via the web interface
   - Configure HTTP checks, ping checks, or Graphite metrics
   - Set up alert policies and on-call schedules

4. **Set up alerting**:
   - Configure email settings for notifications
   - Optionally set up Twilio for SMS/voice alerts
   - Integrate with Slack for chat notifications

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/cabot:latest --env-file .env"

# View logs
dc logs -f

# View specific service logs
dc logs -f cabot-web

# Restart
dc restart

# Stop
dc down

# Update
dc pull && dc up -d

# Run Django management commands
docker exec -it cabot-web python manage.py <command>
```

## Troubleshooting

### Web interface not loading
Check that PostgreSQL and RabbitMQ are healthy before the web container starts. View logs with `dc logs cabot-postgres cabot-rabbitmq`.

### Alerts not sending
Verify email configuration. Check worker logs with `dc logs cabot-worker` for errors.

### Checks not running
Ensure the beat container is running: `dc logs cabot-beat`. Check that `CELERY_BROKER_URL` is correct.

### Container not healthy
Check logs with `dc logs <container>` and ensure all required environment variables are set.

## Links

- [Cabot Documentation](https://cabotapp.com/qs/quickstart.html)
- [Cabot on Docker Hub](https://hub.docker.com/r/cabotapp/cabot)
- [Cabot GitHub](https://github.com/arachnys/cabot)
