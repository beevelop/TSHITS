# Deployment Guide

Complete guide for deploying BeeCompose services in production environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [First-Time Setup](#first-time-setup)
3. [Deployment Methods](#deployment-methods)
4. [Environment Configuration](#environment-configuration)
5. [Multi-Service Deployments](#multi-service-deployments)
6. [Override Files](#override-files)
7. [Production Checklist](#production-checklist)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required

| Component | Minimum Version | Check Command |
|-----------|-----------------|---------------|
| Docker | 25.0+ | `docker --version` |
| Docker Compose | v2.24+ | `docker compose version` |

### Optional

| Component | Purpose |
|-----------|---------|
| CloudFlare Account | DNS-01 Let's Encrypt challenge (Traefik) |
| External DNS | Point domains to your server |
| Firewall | Open ports 80, 443 for web traffic |

### Version Check

```bash
# Verify Docker version (must be 25.0+ for OCI support)
docker --version
# Docker version 25.0.0, build ...

# Verify Compose version
docker compose version
# Docker Compose version v2.24.0
```

> **Important:** OCI artifact deployment requires Docker 25.0 or later. For older versions, use the [Clone and Customize](#method-2-clone-and-customize) method.

---

## First-Time Setup

### 1. Create Working Directory

```bash
mkdir -p ~/beecompose
cd ~/beecompose
```

### 2. Create Traefik Network

All BeeCompose services connect through a shared Traefik network:

```bash
docker network create traefik_default
```

### 3. Deploy Traefik (Reverse Proxy)

Traefik handles SSL termination and routing for all services.

```bash
# Create Traefik environment
cat > traefik.env << 'EOF'
COMPOSE_PROJECT_NAME=traefik
TRAEFIK_DOMAIN=traefik.example.com
CLOUDFLARE_EMAIL=your@email.com
CLOUDFLARE_API_KEY=your-cloudflare-api-key
ACME_EMAIL=your@email.com
EOF

# Deploy Traefik
docker compose \
  -f oci://ghcr.io/beevelop/traefik:latest \
  --env-file traefik.env \
  up -d

# Verify it's running
docker compose \
  -f oci://ghcr.io/beevelop/traefik:latest \
  --env-file traefik.env \
  ps
```

### 4. Verify DNS

Ensure your domain points to your server's IP:

```bash
dig +short gitlab.example.com
# Should return your server's IP
```

---

## Deployment Methods

### Method 1: OCI Artifacts (Recommended)

Deploy directly from GitHub Container Registry without cloning the repository.

```bash
# Create environment file for your service
cat > gitlab.env << 'EOF'
COMPOSE_PROJECT_NAME=gitlab
SERVICE_DOMAIN=gitlab.example.com
DB_USER=gitlab
DB_PASS=your-secure-password
GITLAB_ROOT_PASSWORD=your-root-password
EOF

# Deploy
docker compose \
  -f oci://ghcr.io/beevelop/gitlab:latest \
  --env-file gitlab.env \
  up -d
```

**Advantages:**
- No local files to maintain
- Always get latest configuration
- Cleaner server setup

**Limitations:**
- Requires Docker 25.0+
- Cannot customize compose file directly

### Method 2: Clone and Customize

Clone the repository for full customization control.

```bash
# Clone repository
git clone https://github.com/beevelop/beecompose.git
cd beecompose/services/gitlab

# Create environment from example
cp .env.example .env.production
vim .env.production  # Edit with your values

# Deploy
docker compose --env-file .env.production up -d
```

**Advantages:**
- Full control over compose configuration
- Works with any Docker version
- Easy to customize with override files

**Limitations:**
- Must manually update for new versions
- Local files to maintain

---

## Environment Configuration

### Required Variables

Every service needs these core variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Unique project identifier | `gitlab` |
| `SERVICE_DOMAIN` | Public hostname | `gitlab.example.com` |

### Database Variables

Services with databases need:

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_USER` | Database username | `gitlab` |
| `DB_PASS` | Database password | `secure-password` |
| `DB_NAME` | Database name | `gitlab_production` |

### Generating Secure Passwords

```bash
# Generate a secure password
openssl rand -base64 32

# Generate multiple passwords
for i in {1..5}; do openssl rand -base64 32; done
```

### Environment File Template

```bash
# Core settings
COMPOSE_PROJECT_NAME=myservice
SERVICE_DOMAIN=myservice.example.com

# Database
DB_USER=myservice
DB_PASS=$(openssl rand -base64 32)
DB_NAME=myservice_production

# Application secrets
SECRET_KEY=$(openssl rand -base64 64)

# SMTP (optional)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=notifications@example.com
SMTP_PASS=smtp-password
```

### Service-Specific Variables

Check each service's `.env.example` file for required variables:

```bash
# View example configuration
curl -s https://raw.githubusercontent.com/beevelop/beecompose/main/services/gitlab/.env.example
```

---

## Multi-Service Deployments

### Shared Infrastructure Pattern

Deploy shared services first, then applications:

```bash
# 1. Core infrastructure
docker compose -f oci://ghcr.io/beevelop/traefik:latest --env-file traefik.env up -d

# 2. Shared databases (if needed)
docker compose -f oci://ghcr.io/beevelop/mysql:latest --env-file mysql.env up -d

# 3. Applications
docker compose -f oci://ghcr.io/beevelop/gitlab:latest --env-file gitlab.env up -d
docker compose -f oci://ghcr.io/beevelop/metabase:latest --env-file metabase.env up -d
```

### Managing Multiple Services

Create a deployment script:

```bash
#!/bin/bash
# deploy-all.sh

set -euo pipefail

SERVICES=(
  "traefik:traefik.env"
  "gitlab:gitlab.env"
  "metabase:metabase.env"
)

for entry in "${SERVICES[@]}"; do
  SERVICE="${entry%%:*}"
  ENV_FILE="${entry##*:}"
  
  echo "=== Deploying ${SERVICE} ==="
  docker compose \
    -f "oci://ghcr.io/beevelop/${SERVICE}:latest" \
    --env-file "${ENV_FILE}" \
    up -d
done

echo "=== All services deployed ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Checking Status

```bash
# View all running containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# View all volumes
docker volume ls

# View Traefik routing
docker compose -f oci://ghcr.io/beevelop/traefik:latest --env-file traefik.env logs traefik | grep "Adding route"
```

---

## Override Files

When using the clone method, customize services with override files.

### Creating an Override File

```bash
cd beecompose/services/gitlab

# Create override file
cat > docker-compose.override.yml << 'EOF'
services:
  gitlab:
    environment:
      - GITLAB_EXTRA_SETTING=value
    deploy:
      resources:
        limits:
          memory: 8G
EOF

# Deploy (override is automatically applied)
docker compose --env-file .env.production up -d
```

### Common Override Patterns

**Add resource limits:**
```yaml
services:
  gitlab:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
```

**Mount additional volumes:**
```yaml
services:
  gitlab:
    volumes:
      - ./custom-config:/etc/gitlab/custom:ro
```

**Add extra environment variables:**
```yaml
services:
  gitlab:
    environment:
      - CUSTOM_VAR=value
```

**Change restart policy:**
```yaml
services:
  gitlab:
    restart: always
```

---

## Production Checklist

### Before Deployment

- [ ] Docker 25.0+ installed
- [ ] `traefik_default` network created
- [ ] DNS records configured
- [ ] Firewall ports 80, 443 open
- [ ] Environment files created with secure passwords
- [ ] Backup strategy planned

### After Deployment

- [ ] All containers showing `(healthy)` status
- [ ] SSL certificates issued (check Traefik logs)
- [ ] Application accessible via HTTPS
- [ ] Backup automation configured
- [ ] Monitoring/alerting set up

### Security Checklist

- [ ] No default passwords in production
- [ ] Environment files have restricted permissions (`chmod 600`)
- [ ] Unnecessary ports not exposed
- [ ] Regular image updates scheduled
- [ ] Backup encryption enabled

### Environment File Security

```bash
# Restrict permissions on environment files
chmod 600 *.env

# Verify permissions
ls -la *.env
# -rw------- 1 user user 256 Jan 21 12:00 gitlab.env
```

---

## Troubleshooting

### Service Won't Start

**Check logs:**
```bash
docker compose -f oci://ghcr.io/beevelop/gitlab:latest --env-file gitlab.env logs
```

**Check container status:**
```bash
docker compose -f oci://ghcr.io/beevelop/gitlab:latest --env-file gitlab.env ps
```

**Verify environment variables:**
```bash
docker compose -f oci://ghcr.io/beevelop/gitlab:latest --env-file gitlab.env config
```

### Health Check Failures

**View health status:**
```bash
docker inspect --format='{{json .State.Health}}' gitlab | jq
```

**Check health check logs:**
```bash
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' gitlab
```

### Network Issues

**Verify Traefik network:**
```bash
docker network inspect traefik_default
```

**Check if service is connected:**
```bash
docker inspect gitlab --format='{{json .NetworkSettings.Networks}}' | jq
```

### SSL Certificate Issues

**Check Traefik ACME logs:**
```bash
docker compose -f oci://ghcr.io/beevelop/traefik:latest --env-file traefik.env logs | grep -i acme
```

**Verify DNS is correct:**
```bash
dig +short gitlab.example.com
```

### Volume Issues

**List service volumes:**
```bash
docker volume ls --filter "name=gitlab"
```

**Inspect volume:**
```bash
docker volume inspect gitlab_app_data
```

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `network traefik_default not found` | Traefik network doesn't exist | `docker network create traefik_default` |
| `port is already allocated` | Another service using the port | Stop conflicting service or change port |
| `OCI artifact not found` | Service not published or wrong tag | Check artifact exists on GHCR |
| `manifest unknown` | Wrong image tag | Verify tag on ghcr.io/beevelop |

### Getting Help

1. Check container logs for specific error messages
2. Verify environment file has all required variables
3. Ensure prerequisites are met (Docker 25.0+, network exists)
4. Review [CI/CD documentation](.github/CI-CD.md) for service-specific notes
5. Open an issue on GitHub if the problem persists

---

## Next Steps

- [Backup Guide](BACKUP.md) - Set up automated backups
- [Migration Guide](MIGRATION.md) - Migrate from legacy bee scripts
- [Service Audit](AUDIT.md) - Review all available services
