# BeeCompose

**Production-ready Docker Compose stacks, published as OCI artifacts.**

A curated collection of Docker Compose configurations for self-hosted services. Started in April 2020, BeeCompose provides production-ready setups for 30 popular self-hosted applications with Traefik integration, native healthchecks, and one-command deployment from GitHub Container Registry.

## Quick Start

### Deploy from GHCR (Recommended)

Deploy any service directly from GitHub Container Registry without cloning the repository:

```bash
# 1. Create your environment file
cat > .env.production << 'EOF'
COMPOSE_PROJECT_NAME=gitlab
SERVICE_DOMAIN=gitlab.example.com
DB_USER=gitlab
DB_PASS=your-secure-password
GITLAB_ROOT_PASSWORD=your-root-password
EOF

# 2. Deploy from OCI artifact
docker compose \
  -f oci://ghcr.io/beevelop/gitlab:latest \
  --env-file .env.production \
  up -d

# 3. Check status
docker compose \
  -f oci://ghcr.io/beevelop/gitlab:latest \
  --env-file .env.production \
  ps
```

### Clone and Customize

For customization or development:

```bash
# Clone the repository
git clone https://github.com/beevelop/beecompose.git
cd beecompose/services/gitlab

# Configure environment
cp .env.example .env.production
# Edit .env.production with your settings

# Deploy
docker compose --env-file .env.production up -d
```

## Prerequisites

| Requirement | Minimum Version | Notes |
|-------------|-----------------|-------|
| Docker | 25.0+ | Required for OCI artifact support |
| Docker Compose | v2.24+ | Bundled with Docker Desktop |

**Optional:** CloudFlare account for DNS-01 Let's Encrypt challenge (used by Traefik).

> **Note:** OCI artifact deployment (`docker compose -f oci://...`) requires Docker 25.0 or later.
> For older Docker versions, use the "Clone and Customize" method.

## Available Services

All services are published to `ghcr.io/beevelop/<service>:<version>`.

| Service | Description | OCI Artifact |
|---------|-------------|--------------|
| **bitwarden** | Password manager (Vaultwarden) | `ghcr.io/beevelop/bitwarden` |
| **cabot** | Monitoring and alerts | `ghcr.io/beevelop/cabot` |
| **confluence** | Atlassian documentation | `ghcr.io/beevelop/confluence` |
| **crowd** | Atlassian SSO | `ghcr.io/beevelop/crowd` |
| **dependency-track** | Dependency security analysis | `ghcr.io/beevelop/dependency-track` |
| **directus** | Headless CMS and REST API | `ghcr.io/beevelop/directus` |
| **duckling** | NLP text parser | `ghcr.io/beevelop/duckling` |
| **gitlab** | Git hosting with CI/CD | `ghcr.io/beevelop/gitlab` |
| **graylog** | Log aggregation | `ghcr.io/beevelop/graylog` |
| **huginn** | Self-hosted IFTTT/Zapier | `ghcr.io/beevelop/huginn` |
| **jira** | Atlassian project management | `ghcr.io/beevelop/jira` |
| **keycloak** | Identity and access management | `ghcr.io/beevelop/keycloak` |
| **metabase** | Database analytics | `ghcr.io/beevelop/metabase` |
| **minio** | S3-compatible object storage | `ghcr.io/beevelop/minio` |
| **monica** | Personal CRM | `ghcr.io/beevelop/monica` |
| **mysql** | MySQL database server | `ghcr.io/beevelop/mysql` |
| **nexus** | Binary repository manager | `ghcr.io/beevelop/nexus` |
| **openvpn** | OpenVPN server | `ghcr.io/beevelop/openvpn` |
| **phpmyadmin** | MySQL web administration | `ghcr.io/beevelop/phpmyadmin` |
| **redash** | Data visualization | `ghcr.io/beevelop/redash` |
| **registry** | Private Docker registry | `ghcr.io/beevelop/registry` |
| **rundeck** | Infrastructure automation | `ghcr.io/beevelop/rundeck` |
| **sentry** | Error tracking | `ghcr.io/beevelop/sentry` |
| **shields** | Badge generation | `ghcr.io/beevelop/shields` |
| **sonarqube** | Code quality analysis | `ghcr.io/beevelop/sonarqube` |
| **statping** | Status page and monitoring | `ghcr.io/beevelop/statping` |
| **traefik** | Reverse proxy with Let's Encrypt | `ghcr.io/beevelop/traefik` |
| **tus** | Resumable file uploads | `ghcr.io/beevelop/tus` |
| **weblate** | Translation management | `ghcr.io/beevelop/weblate` |
| **zabbix** | Enterprise monitoring | `ghcr.io/beevelop/zabbix` |

## Common Operations

| Task | Command |
|------|---------|
| Start service | `docker compose --env-file .env.production up -d` |
| Stop service | `docker compose --env-file .env.production down` |
| View logs | `docker compose --env-file .env.production logs -f` |
| Check status | `docker compose --env-file .env.production ps` |
| Update images | `docker compose --env-file .env.production pull && docker compose --env-file .env.production up -d` |
| Destroy (with data) | `docker compose --env-file .env.production down -v --rmi all` |

### Using OCI Artifacts

When deploying from GHCR, include the OCI URL in each command:

```bash
# Define convenience alias
alias dc="docker compose -f oci://ghcr.io/beevelop/gitlab:latest --env-file .env.production"

# Now use it for all operations
dc up -d
dc logs -f
dc ps
dc down
```

## Project Structure

```
beecompose/
├── .dclintrc.yaml            # Docker Compose linter configuration
├── .github/
│   ├── workflows/
│   │   ├── ci-cd.yml         # CI/CD pipeline
│   │   └── publish-oci.yml   # OCI artifact publishing
│   └── CI-CD.md              # Pipeline documentation
├── docs/
│   ├── AUDIT.md              # Service inventory
│   ├── BACKUP.md             # Backup and restore procedures
│   ├── DEPLOYMENT.md         # Deployment guide
│   ├── DEPENDENCIES.md       # Service dependency graph
│   ├── MIGRATION.md          # Migration from legacy setup
│   ├── OCI_NAMING.md         # OCI naming conventions
│   └── TESTING.md            # Testing procedures
└── services/
    └── <service>/
        ├── docker-compose.yml    # Compose configuration
        ├── .env                  # Version tags (committed)
        ├── .env.example          # Example configuration (committed)
        └── .env.<environ>        # Your secrets (gitignored)
```

## Configuration

### Environment Files

Each service uses environment files for configuration:

**.env** (committed) - Version tags:
```bash
GITLAB_VERSION=16.0.0
POSTGRES_VERSION=15-alpine
```

**.env.example** (committed) - Template with placeholders:
```bash
COMPOSE_PROJECT_NAME=gitlab
SERVICE_DOMAIN=gitlab.example.com
DB_USER=bee
DB_PASS=Swordfish
```

**.env.production** (gitignored) - Your actual configuration:
```bash
COMPOSE_PROJECT_NAME=gitlab
SERVICE_DOMAIN=gitlab.yourdomain.com
DB_USER=gitlab
DB_PASS=your-secure-password
```

### Traefik Integration

All services are pre-configured for Traefik v3 reverse proxy with Let's Encrypt SSL.

**First, deploy Traefik:**

```bash
# Create environment
cat > .env.production << 'EOF'
COMPOSE_PROJECT_NAME=traefik
TRAEFIK_DOMAIN=traefik.example.com
CLOUDFLARE_EMAIL=your@email.com
CLOUDFLARE_API_KEY=your-api-key
EOF

# Deploy Traefik
docker compose \
  -f oci://ghcr.io/beevelop/traefik:latest \
  --env-file .env.production \
  up -d
```

**Then deploy other services.** They automatically connect via the `traefik_default` network.

### Named Volumes

All services use Docker named volumes for data persistence. Volume names follow the pattern:

```
${COMPOSE_PROJECT_NAME}_<purpose>

Examples:
- gitlab_app_data
- gitlab_postgres_data
- gitlab_redis_data
```

List volumes for a service:

```bash
docker volume ls --filter "name=gitlab"
```

## Health Checks

All services include native Docker healthcheck directives. Check health status with:

```bash
docker compose --env-file .env.production ps
```

Healthy containers show `(healthy)` in the STATUS column.

## Backups

See [docs/BACKUP.md](docs/BACKUP.md) for comprehensive backup and restore procedures including:

- Tar archive backups
- Database-specific dumps (PostgreSQL, MySQL, MongoDB, Redis)
- Restic for production environments
- Automated backup scripts

Quick backup example:

```bash
# Backup a volume
docker run --rm \
  -v gitlab_postgres_data:/data:ro \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/gitlab_postgres_$(date +%Y%m%d).tar.gz -C /data .
```

## Documentation

| Document | Description |
|----------|-------------|
| [Deployment Guide](docs/DEPLOYMENT.md) | Complete deployment walkthrough |
| [Backup Guide](docs/BACKUP.md) | Backup and restore procedures |
| [Migration Guide](docs/MIGRATION.md) | Migrate from legacy bee scripts |
| [Testing Guide](docs/TESTING.md) | Testing procedures and validation |
| [CI/CD Pipeline](.github/CI-CD.md) | Pipeline architecture and usage |
| [Service Audit](docs/AUDIT.md) | Complete service inventory |
| [OCI Naming](docs/OCI_NAMING.md) | OCI artifact naming conventions |

## CI/CD

The repository includes GitHub Actions pipelines that:

1. **Lint** - Validates all docker-compose.yml files with DCLint
2. **Validate OCI** - Ensures all services are OCI-compatible (no bind mounts)
3. **CVE Scan** - Scans images for vulnerabilities using Trivy
4. **Test** - Validates each service starts correctly
5. **Publish** - Publishes OCI artifacts to GHCR on main branch

See [.github/CI-CD.md](.github/CI-CD.md) for detailed documentation.

## Notes

- **Placeholder Values:** Examples use `example.com`, `bee` (username), and `Swordfish` (password)
- **Traefik Version:** Uses Traefik v3 with Let's Encrypt DNS-01 challenge
- **Restart Policy:** All containers use `restart: unless-stopped`
- **Logging:** JSON logging with `max-size: 500k` and `max-file: 50`
- **Docker Compose:** Files use `version: "3"` (optional but kept for compatibility)

## Contributing

Pull requests are welcome! Please:

1. Follow existing docker-compose patterns
2. Include `.env.example` with placeholder values
3. Use named volumes (no `./data/` bind mounts)
4. Include native Docker healthcheck directives
5. Run DCLint before submitting: `docker run --rm -v "$(pwd):/app" zavoloklom/dclint:latest /app/services/<service> -c /app/.dclintrc.yaml`
6. Test locally with `docker compose --env-file .env.test up -d`

## License

[MIT License](LICENSE)
