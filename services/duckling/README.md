# Duckling

> **OCI Artifact** - Deploy directly from GitHub Container Registry

Duckling is a Haskell library that parses text into structured data. It extracts entities like dates, times, numbers, amounts of money, phone numbers, and more from natural language text.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

### Using bc CLI (Recommended)

```bash
# 1. Create environment file
cat > .env.duckling << 'EOF'
COMPOSE_PROJECT_NAME=duckling
SERVICE_DOMAIN=duckling.example.com
EOF

# 2. Deploy
bc duckling up

# 3. Check status
bc duckling ps
```

> **Note:** Install the bc CLI with: `curl -fsSL https://raw.githubusercontent.com/beevelop/beecompose/main/scripts/install.sh | sudo bash`

### Manual Deployment

```bash
# 1. Create environment file
cat > .env.duckling << 'EOF'
COMPOSE_PROJECT_NAME=duckling
SERVICE_DOMAIN=duckling.example.com
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/duckling:latest --env-file .env.duckling up -d --pull always

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/duckling:latest --env-file .env.duckling ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| duckling | rasa/duckling:0.2.0.2-r3 | Natural language entity extraction API |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Traefik routing | `duckling.example.com` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `duckling` |

## Volumes

This service is stateless and does not require persistent volumes.

## Post-Deployment

1. **Verify the API**: Send a test request to parse text:
   ```bash
   curl -XPOST https://duckling.example.com/parse \
     --data 'locale=en_US&text=tomorrow at 3pm'
   ```

2. **Explore supported dimensions**: Duckling can extract:
   - Time/Date (`time`)
   - Duration (`duration`)
   - Temperature (`temperature`)
   - Number (`number`)
   - Ordinal (`ordinal`)
   - Distance (`distance`)
   - Volume (`volume`)
   - Amount of money (`amount-of-money`)
   - Email (`email`)
   - URL (`url`)
   - Phone number (`phone-number`)

## Common Operations

### Using bc CLI

```bash
bc duckling logs -f     # View logs
bc duckling restart     # Restart
bc duckling down        # Stop
bc duckling update      # Pull and recreate
```

### Using docker compose directly

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/duckling:latest --env-file .env.duckling"

# View logs
dc logs -f

# Restart
dc restart

# Stop
dc down

# Update
dc pull && dc up -d
```

## API Usage

### Parse text for all dimensions
```bash
curl -XPOST https://duckling.example.com/parse \
  --data 'locale=en_US&text=Order 2 pizzas for $15 tomorrow'
```

### Parse specific dimension only
```bash
curl -XPOST https://duckling.example.com/parse \
  --data 'locale=en_US&text=tomorrow at 3pm&dims=["time"]'
```

## Troubleshooting

### Empty response from API
Ensure you're sending POST requests with the correct `locale` and `text` parameters.

### Unsupported locale
Duckling supports many locales but not all. Check the [supported locales](https://github.com/facebook/duckling#supported-languages) documentation.

### Container not healthy
Check logs with `dc logs duckling` and ensure all required environment variables are set.

## Links

- [Official Documentation](https://github.com/facebook/duckling)
- [Docker Hub](https://hub.docker.com/r/rasa/duckling)
- [GitHub](https://github.com/facebook/duckling)
