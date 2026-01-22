# Dependency-Track

> **OCI Artifact** - Deploy directly from GitHub Container Registry

OWASP Dependency-Track - intelligent Component Analysis platform for identifying and reducing risk in the software supply chain through SBOM analysis and vulnerability tracking.

## What is an OCI Artifact?

This is a **Docker Compose OCI artifact**, not a traditional Docker image. It contains a complete docker-compose.yml configuration that you can deploy directly using Docker 25.0+.

## Quick Start

```bash
# 1. Create environment file
cat > .env << 'EOF'
COMPOSE_PROJECT_NAME=dependency-track
SERVICE_DOMAIN=dtrack.example.com
EOF

# 2. Deploy from GHCR
docker compose -f oci://ghcr.io/beevelop/dependency-track:latest --env-file .env up -d

# 3. Check status
docker compose -f oci://ghcr.io/beevelop/dependency-track:latest --env-file .env ps
```

## Prerequisites

- Docker 25.0+ (required for OCI artifact support)
- Docker Compose v2.24+
- Traefik reverse proxy (see [traefik](../traefik/))
- Minimum 4GB RAM recommended (8GB for larger deployments)

## Architecture

| Container | Image | Purpose |
|-----------|-------|---------|
| dtrack | dependencytrack/bundled | API server, frontend, and embedded database |

This deployment uses the **bundled** image which includes:
- API Server (backend)
- Frontend (web UI)
- Embedded H2 database (for small/medium deployments)

For larger deployments, consider using the separate API and frontend images with PostgreSQL.

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_DOMAIN` | Domain for Dependency-Track access | `dtrack.example.com` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Docker Compose project name | `dependency-track` |

## Volumes

| Volume | Purpose |
|--------|---------|
| `dtrack_data` | Application data, embedded database, and vulnerability database |

## Post-Deployment

1. **Wait for startup** - Dependency-Track takes 2-3 minutes to initialize and download vulnerability databases

2. **Access the UI** at `https://dtrack.example.com`

3. **Login with default credentials**:
   - Username: `admin`
   - Password: `admin`
   - **Change the password immediately!**

4. **Initial setup**:
   - Navigate to Administration > Configuration
   - Configure notification settings (email, Slack, etc.)
   - Set up API keys for CI/CD integration

5. **Wait for vulnerability data sync**:
   - Dependency-Track automatically downloads NVD, GitHub Advisories, and other vulnerability data
   - Initial sync can take 15-30 minutes
   - Check progress in Administration > Analyzers

6. **Create projects and upload SBOMs**:
   - Create a project for each application
   - Upload CycloneDX or SPDX SBOMs via UI or API
   - Use CI/CD integration for automated uploads

## Common Operations

```bash
# Define alias for convenience
alias dc="docker compose -f oci://ghcr.io/beevelop/dependency-track:latest --env-file .env"

# View logs
dc logs -f

# Restart
dc restart

# Stop
dc down

# Update
dc pull && dc up -d

# Generate API key (after login)
# Navigate to Administration > Access Management > Teams > Automation > API Keys
```

## CI/CD Integration

### Upload SBOM via API

```bash
# Generate CycloneDX SBOM (example with npm)
npx @cyclonedx/cyclonedx-npm --output-file sbom.json

# Upload to Dependency-Track
curl -X POST "https://dtrack.example.com/api/v1/bom" \
  -H "X-Api-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d @- << EOF
{
  "projectName": "my-project",
  "projectVersion": "1.0.0",
  "autoCreate": true,
  "bom": "$(base64 -w 0 sbom.json)"
}
EOF
```

### GitHub Actions Example

```yaml
- name: Upload SBOM to Dependency-Track
  uses: DependencyTrack/gh-upload-sbom@v3
  with:
    serverHostname: 'dtrack.example.com'
    apiKey: ${{ secrets.DTRACK_API_KEY }}
    project: 'my-project'
    version: ${{ github.ref_name }}
    bomFilename: 'sbom.json'
```

## Troubleshooting

### Slow startup
Dependency-Track requires significant time to initialize, especially on first run when downloading vulnerability databases. The health check has a 120s start period.

### Out of memory
The bundled image requires at least 4GB RAM. For larger deployments with many projects:
- Use separate API server and frontend images
- Configure external PostgreSQL database
- Increase JVM heap size

### Vulnerability data not updating
Check the analyzer status in Administration > Analyzers. Ensure the container has internet access to download vulnerability feeds.

### API returning 401
Verify your API key is correct and has appropriate permissions. Check that the key belongs to a team with the required permissions for your operation.

### Container not healthy
Check logs with `dc logs dtrack`. The API endpoint `/api/version` is used for health checks. Ensure the application has fully started.

## Links

- [Dependency-Track Documentation](https://docs.dependencytrack.org/)
- [Dependency-Track on Docker Hub](https://hub.docker.com/r/dependencytrack/bundled)
- [Dependency-Track GitHub](https://github.com/DependencyTrack/dependency-track)
- [OWASP Dependency-Track](https://owasp.org/www-project-dependency-track/)
- [CycloneDX Specification](https://cyclonedx.org/)
