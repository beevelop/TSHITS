# Traefik

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Cloud-native reverse proxy and load balancer with automatic HTTPS. Supports both direct port exposure with Let's Encrypt and Cloudflare Tunnel mode.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

### Exposed Mode (Default)

Direct port exposure with Let's Encrypt via CloudFlare DNS-01 challenge:

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=traefik
TRAEFIK_MODE=exposed
TRAEFIK_DOMAIN=traefik.example.com
TRAEFIK_EMAIL=admin@example.com
TRAEFIK_AUTH=admin:$$apr1$$your_hashed_password
CLOUDFLARE_EMAIL=admin@example.com
CLOUDFLARE_API_KEY=your_cloudflare_api_key
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/traefik:latest --env-file .env up -d

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/traefik:latest --env-file .env ps
```

### Tunnel Mode

Behind Cloudflare Tunnel - TLS terminated at Cloudflare edge:

```bash
# 1. Deploy cloudflared first (see cloudflared service)
docker compose -f oci://ghcr.io/beevelop/cloudflared:latest --env-file .env.cloudflared up -d

# 2. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=traefik
TRAEFIK_MODE=tunnel
TRAEFIK_BIND_IP=127.0.0.1
TRAEFIK_DASHBOARD_BIND=127.0.0.1
EOF

# 3. Deploy Traefik
docker compose -f oci://ghcr.io/beevelop/traefik:latest --env-file .env up -d
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- **Exposed mode:** CloudFlare account with API access for DNS-01 challenge
- **Tunnel mode:** Cloudflared tunnel configured and running

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| traefik | traefik:v3.6 | Reverse proxy and load balancer |
| traefik-init | alpine:3.23 | Configuration generator (runs once) |

## Modes

| Mode | Description | Ports | TLS Provider |
|------|-------------|-------|--------------|
| `exposed` | Direct internet exposure | 80, 443, 8080 public | Let's Encrypt |
| `tunnel` | Behind Cloudflare Tunnel | 80, 8080 localhost only | Cloudflare Edge |

## Environment Variables

### Mode Selection

| Variable | Default | Description |
|----------|---------|-------------|
| `TRAEFIK_MODE` | `exposed` | Operating mode: `exposed` or `tunnel` |

### Common Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `COMPOSE_PROJECT_NAME` | `traefik` | Docker Compose project name |
| `TRAEFIK_VERSION` | `v3.6` | Traefik image version |
| `TRAEFIK_DOMAIN` | `traefik.example.com` | Domain for Traefik dashboard |
| `TRAEFIK_AUTH` | `admin:$$apr1$$changeme` | Basic auth for dashboard (htpasswd format) |

### Port Configuration (Optional)

| Variable | Default | Description |
|----------|---------|-------------|
| `TRAEFIK_HTTP_PORT` | `80` | HTTP port |
| `TRAEFIK_HTTPS_PORT` | `443` | HTTPS port |
| `TRAEFIK_DASHBOARD_PORT` | `8080` | Dashboard port |
| `TRAEFIK_BIND_IP` | `0.0.0.0` | Bind IP for HTTP/HTTPS ports |
| `TRAEFIK_DASHBOARD_BIND` | `0.0.0.0` | Bind IP for dashboard port |

For tunnel mode, set bind IPs to `127.0.0.1` to ensure only cloudflared can reach Traefik.

### Exposed Mode Only

| Variable | Description | Required |
|----------|-------------|----------|
| `CLOUDFLARE_EMAIL` | CloudFlare account email | Yes |
| `CLOUDFLARE_API_KEY` | CloudFlare Global API key | Yes |
| `TRAEFIK_EMAIL` | Email for Let's Encrypt notifications | No (uses CLOUDFLARE_EMAIL) |

### Network Binding (Optional)

| Variable | Default | Description |
|----------|---------|-------------|
| `TRAEFIK_BIND_IP` | `0.0.0.0` | IP to bind ports 80/443 |
| `TRAEFIK_DASHBOARD_BIND` | `0.0.0.0` | IP to bind dashboard port 8080 |

For tunnel mode, set both to `127.0.0.1` to ensure only cloudflared can reach Traefik.

### Generating Dashboard Credentials

```bash
# Using htpasswd (install: apt install apache2-utils)
htpasswd -nb admin your_password | sed 's/\$/\$\$/g'

# Or using Docker (no install needed)
docker run --rm httpd:alpine htpasswd -nb admin your_password | sed 's/\$/\$\$/g'

# Example output (copy this to TRAEFIK_AUTH):
# admin:$$apr1$$xyz123$$abcdefghijklmnop
```

## Volumes

| Volume | Purpose |
|--------|---------|
| `traefik_config` | Traefik configuration files |
| `traefik_acme_data` | Let's Encrypt certificates (exposed mode) |
| `traefik_logs_data` | Access and error logs |

## Ports

| Port | Purpose |
|------|---------|
| 80 | HTTP (redirects to HTTPS in exposed mode, websecure entrypoint in tunnel mode) |
| 443 | HTTPS (exposed mode only, unused in tunnel mode) |
| 8080 | Traefik dashboard |

## How It Works

### Exposed Mode
```
Internet → Port 80/443 → Traefik → Services
                ↓
         Let's Encrypt (CloudFlare DNS-01)
```

### Tunnel Mode
```
Internet → Cloudflare Edge (TLS) → cloudflared → Traefik:80 → Services
                                        ↓
                               (localhost only, no public ports)
```

In tunnel mode:
- The `websecure` entrypoint listens on port 80 (HTTP from cloudflared)
- Existing service labels (`entrypoints=websecure`, `tls=true`) work unchanged
- TLS labels are safely ignored since Cloudflare handles TLS

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/traefik:latest --env-file .env"

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

### Mount Error: read-only file system

If you see an error about mounting to a read-only file system, ensure you're using the latest version which mounts ACME data to `/acme` instead of `/etc/traefik/acme`.

### Certificate not issuing (Exposed Mode)

Check CloudFlare API credentials and ensure the domain's DNS is managed by CloudFlare:
```bash
dc logs traefik | grep -i acme
```

### Dashboard 401 Unauthorized

Verify `TRAEFIK_AUTH` is properly escaped (double `$$` in compose files) and matches htpasswd format.

### Services not discovered

Ensure services have `traefik.enable=true` label and are connected to `traefik_default` network.

### Tunnel mode: cloudflared can't reach Traefik

Ensure both are on the same Docker network and cloudflared is configured to route to `http://traefik:80`.

## Links

- [Official Documentation](https://doc.traefik.io/traefik/)
- [Docker Hub](https://hub.docker.com/_/traefik)
- [GitHub](https://github.com/traefik/traefik)
