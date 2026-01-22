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

### Required (Standard Mode)

| Variable | Description | Example |
|----------|-------------|---------|
| `CLOUDFLARE_EMAIL` | CloudFlare account email | `admin@example.com` |
| `CLOUDFLARE_API_KEY` | CloudFlare Global API key | `your_api_key` |

> **Note:** CloudFlare credentials are only required for standard mode (direct port exposure with Let's Encrypt).
> In tunnel-only mode, TLS is terminated at Cloudflare edge, so no API credentials are needed.

### Required (Tunnel-Only Mode)

No CloudFlare API credentials needed! The only requirement is deploying [cloudflared](../cloudflared/).

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `traefik` |
| `TRAEFIK_DOMAIN` | Domain for Traefik dashboard | `traefik.example.com` |
| `TRAEFIK_EMAIL` | Email for Let's Encrypt notifications | Uses `CLOUDFLARE_EMAIL` |
| `TRAEFIK_AUTH` | Basic auth for dashboard (htpasswd format) | `admin:$$apr1$$changeme` |

### Generating Dashboard Credentials

Generate `TRAEFIK_AUTH` credentials using htpasswd:

```bash
# Using htpasswd (install: apt install apache2-utils)
htpasswd -nb admin your_password | sed 's/\$/\$\$/g'

# Or using Docker (no install needed)
docker run --rm httpd:alpine htpasswd -nb admin your_password | sed 's/\$/\$\$/g'

# Example output (copy this to TRAEFIK_AUTH):
# admin:$$apr1$$xyz123$$abcdefghijklmnop
```

The `sed` command doubles the `$` signs, which is required for docker-compose variable escaping.

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

For enhanced security, run Traefik behind a Cloudflare Tunnel. This removes direct internet exposure and eliminates the need for CloudFlare API credentials.

### Benefits

- **No public ports** - Ports 80/443 not exposed to internet
- **No CloudFlare API keys** - TLS terminated at Cloudflare edge
- **Zero-trust access** - Control access via Cloudflare Access policies
- **DDoS protection** - Cloudflare absorbs attacks at edge
- **Existing labels work** - No changes to service configurations

### Architecture

```
Internet -> Cloudflare Edge (TLS) -> cloudflared -> Traefik (HTTP) -> Services
                                         |
                                (no public ports exposed)
```

### Setup

```bash
# 1. Deploy cloudflared first (see ../cloudflared/)
docker compose -f oci://ghcr.io/beevelop/cloudflared:latest --env-file .env.cloudflared up -d

# 2. Generate tunnel-only config
docker compose -f docker-compose.yml -f docker-compose.tunnel.yml \
  --profile init up traefik-init

# 3. Deploy Traefik in tunnel-only mode
docker compose -f docker-compose.yml -f docker-compose.tunnel.yml up -d
```

### Minimal Environment File (Tunnel-Only)

```bash
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=traefik
EOF
```

That's it! No CloudFlare API credentials, no domain configuration, no htpasswd auth needed for basic setup.

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
