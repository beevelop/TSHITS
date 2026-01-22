# phpMyAdmin

> **OCI Artifact** - Deploy directly from GitHub Container Registry

phpMyAdmin is a free, open-source web-based database administration tool for MySQL and MariaDB. This stack provides a production-ready instance with Traefik integration and support for connecting to any MySQL/MariaDB server.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=phpmyadmin
SERVICE_DOMAIN=pma.example.com
PMA_VERSION=5.2.3
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/phpmyadmin:latest --env-file .env up -d

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/phpmyadmin:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))
- MySQL or MariaDB server to manage

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| phpmyadmin | phpmyadmin/phpmyadmin:5.2.3 | Web-based MySQL administration |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Traefik routing | `pma.example.com` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `phpmyadmin` |
| `PMA_VERSION` | phpMyAdmin image version | `5.2.3` |

### Pre-configured

These are set in the docker-compose.yml:

| Variable | Value | Purpose |
|----------|-------|---------|
| `PMA_ARBITRARY` | `1` | Allow connecting to any MySQL server |
| `PMA_ABSOLUTE_URI` | `https://${SERVICE_DOMAIN}` | Correct URL generation behind proxy |

## Post-Deployment

### Connecting to a Database

1. Navigate to `https://pma.example.com`
2. Enter the MySQL server hostname (e.g., `mysql`, `db.example.com`, or IP address)
3. Enter your MySQL username and password
4. Click "Go" to connect

### Connecting to Docker MySQL Containers

If your MySQL container is on the same Docker network:
- Use the container name as the server (e.g., `mysql`)
- Ensure both containers share a network (add phpMyAdmin to your MySQL network)

### Network Configuration

To connect to MySQL containers in other stacks, add the target network:

```yaml
# Add to your docker-compose override
networks:
  mysql:
    external:
      name: mysql_mysql
```

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/phpmyadmin:latest --env-file .env"

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

### Cannot connect to MySQL server
- Verify MySQL server is running and accessible
- Check if phpMyAdmin can reach the MySQL network
- For external servers, ensure firewalls allow the connection

### Login page redirects or shows errors
Verify `PMA_ABSOLUTE_URI` matches your actual domain with HTTPS.

### Session issues behind proxy
Ensure Traefik is correctly forwarding headers. The `PMA_ABSOLUTE_URI` setting helps resolve proxy-related issues.

### Container not healthy
Check logs with `dc logs phpmyadmin` and ensure all required environment variables are set.

## Links

- [Official Documentation](https://www.phpmyadmin.net/docs/)
- [Docker Hub](https://hub.docker.com/r/phpmyadmin/phpmyadmin)
- [GitHub](https://github.com/phpmyadmin/phpmyadmin)
