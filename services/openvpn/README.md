# OpenVPN

> **OCI Artifact** - Deploy directly from GitHub Container Registry

OpenVPN is a robust open-source VPN solution. This stack provides both UDP (default, port 1194) and TCP (port 443, for restrictive networks) configurations with easy client management.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

### Using bc CLI (Recommended)

```bash
# 1. Create environment file
cat > .env.openvpn << 'EOF'
COMPOSE_PROJECT_NAME=openvpn
SERVICE_DOMAIN=vpn.example.com
OPENVPN_VERSION=2.4
EOF

# 2. Deploy
bc openvpn up

# 3. Check status
bc openvpn ps
```

> **Note:** Install the bc CLI with: `curl -fsSL https://raw.githubusercontent.com/beevelop/beecompose/main/scripts/install.sh | sudo bash`

### Manual Deployment

```bash
# 1. Create environment file
cat > .env.openvpn << 'EOF'
COMPOSE_PROJECT_NAME=openvpn
SERVICE_DOMAIN=vpn.example.com
OPENVPN_VERSION=2.4
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/openvpn:latest --env-file .env.openvpn up -d --pull always

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/openvpn:latest --env-file .env.openvpn ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Public IP or domain for VPN server

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| openvpn | kylemanna/openvpn:2.4 | OpenVPN server (UDP) |
| openvpn-tcp | kylemanna/openvpn:2.4 | OpenVPN server (TCP, profile: `tcp`) |
| openvpn-init | kylemanna/openvpn:2.4 | PKI initialization (profile: `init`) |
| openvpn-tcp-init | kylemanna/openvpn:2.4 | TCP PKI initialization (profile: `tcp-init`) |
| openvpn-add-client | kylemanna/openvpn:2.4 | Client certificate generator (profile: `add-client`) |

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | VPN server domain/hostname | `vpn.example.com` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `openvpn` |
| `OPENVPN_VERSION` | OpenVPN image version | `2.4` |
| `OPENVPN_SERVER_URL` | UDP server URL | `udp://${SERVICE_DOMAIN}` |
| `OPENVPN_TCP_SERVER_URL` | TCP server URL | `tcp://${SERVICE_DOMAIN}:443` |
| `CLIENT_NAME` | Client name for certificate generation | `client` |

## Volumes

| Volume | Purpose |
|--------|---------|
| `openvpn_udp_config` | UDP server PKI and configuration (`/etc/openvpn`) |
| `openvpn_tcp_config` | TCP server PKI and configuration (`/etc/openvpn`) |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 1194 | UDP | OpenVPN server (standard) |
| 443 | TCP | OpenVPN server (for restrictive networks) |

## Post-Deployment

### Initialize the PKI (First Time Only)

Before starting the VPN server, initialize the PKI infrastructure:

```bash
# Define alias
alias dc="docker compose -f oci://ghcr.io/beevelop/openvpn:latest --env-file .env"

# Initialize UDP server (required)
dc --profile init run --rm openvpn-init

# Initialize TCP server (optional, for restrictive networks)
dc --profile tcp-init run --rm openvpn-tcp-init
```

### Generate Client Certificates

```bash
# Set client name
export CLIENT_NAME=myuser

# Generate client certificate and get .ovpn file
dc --profile add-client run --rm openvpn-add-client > ${CLIENT_NAME}.ovpn
```

Alternatively, use docker exec:

```bash
# Generate certificate
docker exec openvpn easyrsa build-client-full myuser nopass

# Export client config
docker exec openvpn ovpn_getclient myuser > myuser.ovpn
```

### Start TCP Server (Optional)

To also run the TCP server for restrictive networks:

```bash
dc --profile tcp up -d openvpn-tcp
```

## Common Operations

### Using bc CLI

```bash
bc openvpn logs -f     # View logs
bc openvpn restart     # Restart
bc openvpn down        # Stop
bc openvpn update      # Pull and recreate
```

### Using docker compose directly

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/openvpn:latest --env-file .env.openvpn"

# View logs
dc logs -f

# Restart
dc restart

# Stop
dc down

# Update
dc pull && dc up -d

# List connected clients
docker exec openvpn cat /tmp/openvpn-status.log

# Revoke a client certificate
docker exec openvpn easyrsa revoke myuser
docker exec openvpn easyrsa gen-crl
docker exec openvpn cp /etc/openvpn/pki/crl.pem /etc/openvpn/crl.pem
```

## Troubleshooting

### PKI not initialized
Run the init profile before starting: `dc --profile init run --rm openvpn-init`

### Client cannot connect
- Verify firewall allows UDP 1194 (or TCP 443)
- Check that `SERVICE_DOMAIN` resolves to the server IP
- Ensure client .ovpn file was generated correctly

### Container not healthy
Check logs with `dc logs openvpn` and ensure all required environment variables are set.

## Links

- [Official Documentation](https://openvpn.net/community-resources/)
- [Docker Hub](https://hub.docker.com/r/kylemanna/openvpn)
- [GitHub](https://github.com/kylemanna/docker-openvpn)
