# Traefik

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Cloud-native reverse proxy and load balancer with automatic HTTPS via Let's Encrypt and CloudFlare DNS-01 challenge.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=traefik
TRAEFIK_DOMAIN=traefik.example.com
TRAEFIK_EMAIL=admin@example.com
TRAEFIK_AUTH=admin:$$apr1$$your_hashed_password
CLOUDFLARE_EMAIL=admin@example.com
CLOUDFLARE_API_KEY=your_cloudflare_api_key
EOF

# 2. Generate config (run init profile first)
docker compose -f oci://ghcr.io/beevelop/traefik:latest --env-file .env --profile init up traefik-init

# 3. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/traefik:latest --env-file .env up -d

# 4. Check status
docker compose -f oci://ghcr.io/beevelop/traefik:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- CloudFlare account with API access for DNS-01 challenge
- Domain with DNS managed by CloudFlare

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| traefik | traefik:v3.6 | Reverse proxy and load balancer |
| traefik-init | alpine:3.23 | Configuration generator (init profile) |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `CLOUDFLARE_EMAIL` | CloudFlare account email | `admin@example.com` |
| `CLOUDFLARE_API_KEY` | CloudFlare Global API key | `your_api_key` |
| `TRAEFIK_AUTH` | Basic auth for dashboard (htpasswd format) | `admin:$$apr1$$...` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `traefik` |
| `TRAEFIK_DOMAIN` | Domain for Traefik dashboard | `traefik.example.com` |
| `TRAEFIK_EMAIL` | Email for Let's Encrypt notifications | Uses `CLOUDFLARE_EMAIL` |

## Volumes

| Volume | Purpose |
|--------|---------|
| `traefik_config` | Traefik configuration files |
| `traefik_acme_data` | Let's Encrypt certificates |
| `traefik_logs_data` | Access and error logs |
| `traefik_certs_data` | Custom certificates |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 80 | TCP | HTTP (redirects to HTTPS) |
| 443 | TCP | HTTPS |
| 8080 | TCP | Traefik dashboard |

## Post-Deployment

1. **Generate htpasswd credentials** for dashboard access:
   ```bash
   htpasswd -nb admin your_password | sed -e s/\\$/\\$\\$/g
   ```

2. **Access the dashboard** at `https://traefik.example.com/dashboard/`

3. **Verify HTTPS** is working by checking certificate status in the dashboard

4. **Create the external network** if not already present:
   ```bash
   docker network create traefik_default
   ```

### Configuration

The init container generates `traefik.yml` with:
- HTTP to HTTPS redirect
- Let's Encrypt with CloudFlare DNS-01 challenge
- Docker provider (auto-discovery)
- Access logging enabled

## Tunnel-Only Mode (Cloudflare Tunnel)

For enhanced security, you can run Traefik behind a Cloudflare Tunnel, removing direct internet exposure. This requires the [cloudflared](../cloudflared/) service.

### Architecture

```
Internet -> Cloudflare Edge -> cloudflared -> Traefik -> Services
                                   |
                          (no public ports exposed)
```

### Setup

```bash
# 1. Deploy cloudflared service first (see ../cloudflared/)

# 2. Deploy Traefik in tunnel-only mode
dc -f docker-compose.yml -f docker-compose.tunnel.yml up -d
```

### What Changes

| Mode | Port 80 | Port 443 | Port 8080 |
|------|---------|----------|-----------|
| **Standard** | Public | Public | Public |
| **Tunnel-only** | Not exposed | Not exposed | localhost only |

In tunnel-only mode:
- All public traffic flows through Cloudflare Tunnel
- Dashboard accessible only at `127.0.0.1:8080` for local debugging
- Cloudflare Access policies control who can reach services
- DDoS protection and WAF provided by Cloudflare

See [cloudflared README](../cloudflared/README.md) for complete setup instructions.

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

# Regenerate config
dc --profile init up traefik-init

# Deploy in tunnel-only mode
dc -f docker-compose.yml -f docker-compose.tunnel.yml up -d
```

## Troubleshooting

### Certificate not issuing
Check CloudFlare API credentials and ensure the domain's DNS is managed by CloudFlare. View ACME logs:
```bash
dc logs traefik | grep -i acme
```

### Dashboard 401 Unauthorized
Verify `TRAEFIK_AUTH` is properly escaped (double `$$` in compose files) and matches htpasswd format.

### Services not discovered
Ensure services have `traefik.enable=true` label and are connected to `traefik_default` network.

### Container not healthy
Check logs with `dc logs traefik` and ensure all required environment variables are set.

## Links

- [Official Documentation](https://doc.traefik.io/traefik/)
- [Docker Hub](https://hub.docker.com/_/traefik)
- [GitHub](https://github.com/traefik/traefik)
