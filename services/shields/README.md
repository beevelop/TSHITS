# Shields

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Self-hosted Shields.io badge service for generating dynamic status badges for your projects and documentation.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=shields
SERVICE_DOMAIN=shields.example.com
SHIELDS_TAG=honey
VARNISH_TAG=v2021.06.1
GH_CLIENT_ID=
GH_CLIENT_SECRET=
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/shields:latest --env-file .env up -d

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/shields:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))
- GitHub OAuth App (optional, for higher API rate limits)

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| shields | beevelop/shields:honey | Shields.io badge generator |
| shields-varnish | beevelop/varnish:v2021.06.1 | Caching proxy for performance |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Shields | `shields.example.com` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `shields` |
| `SHIELDS_TAG` | Shields image tag | `honey` |
| `VARNISH_TAG` | Varnish image tag | `v2021.06.1` |
| `GH_CLIENT_ID` | GitHub OAuth App client ID | (empty) |
| `GH_CLIENT_SECRET` | GitHub OAuth App client secret | (empty) |

## Post-Deployment

### Test Badge Generation

Generate a test badge to verify the service is working:

```bash
curl -I "https://shields.example.com/badge/status-working-brightgreen"
```

### Configure GitHub OAuth (Recommended)

To increase GitHub API rate limits (from 60 to 5000 requests/hour):

1. Create a GitHub OAuth App:
   - Go to GitHub Settings > Developer settings > OAuth Apps
   - Create new OAuth App
   - Set Homepage URL to `https://shields.example.com`
   - Set Authorization callback URL to `https://shields.example.com/callback`

2. Update your `.env` with the credentials:
   ```bash
   GH_CLIENT_ID=your_client_id
   GH_CLIENT_SECRET=your_client_secret
   ```

3. Restart the stack:
   ```bash
   dc down && dc up -d
   ```

### Example Badges

```markdown
<!-- Static badge -->
![Custom Badge](https://shields.example.com/badge/custom-badge-blue)

<!-- GitHub stars -->
![GitHub Stars](https://shields.example.com/github/stars/user/repo)

<!-- npm version -->
![npm Version](https://shields.example.com/npm/v/package-name)

<!-- Build status -->
![Build](https://shields.example.com/github/actions/workflow/status/user/repo/ci.yml)
```

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/shields:latest --env-file .env"

# View logs
dc logs -f

# View Varnish cache stats
docker exec shields-varnish varnishstat

# Restart
dc restart

# Stop
dc down

# Update
dc pull && dc up -d
```

### Clear Varnish Cache

```bash
docker exec shields-varnish varnishadm "ban req.url ~ ."
```

## Troubleshooting

### Badges Not Loading

1. Check if Varnish is healthy:
   ```bash
   dc logs shields-varnish
   ```

2. Test the backend directly (bypassing cache):
   ```bash
   docker exec shields curl -I http://backend/badge/test-badge-green
   ```

### GitHub API Rate Limited

If you see rate limit errors, configure GitHub OAuth (see above). Verify credentials are set:

```bash
docker exec shields env | grep GH_
```

### Slow Badge Generation

Varnish caches badges to improve performance. First requests may be slow; subsequent requests should be fast.

### Container not healthy

Check logs with `dc logs shields` and ensure all required environment variables are set.

## Links

- [Official Shields.io](https://shields.io/)
- [Shields.io GitHub](https://github.com/badges/shields)
- [Badge Examples](https://shields.io/badges)
