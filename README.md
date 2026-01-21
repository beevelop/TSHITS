# T-SHITS

**T**he **S**elf-**H**osted, **I**ndependent **T**echnology **S**tack (pronounced "T-SHITS")

A curated collection of Docker Compose configurations for self-hosted services. Started in April 2020, T-SHITS provides production-ready setups for 30 popular self-hosted applications with built-in reverse proxy integration, encrypted secrets management, and automated backups.

## Features

- **30 Pre-configured Services** - From GitLab to Keycloak, ready to deploy
- **Traefik Integration** - Automatic reverse proxy with Let's Encrypt SSL (CloudFlare DNS-01)
- **Encrypted Secrets** - AES-256-CBC encryption for environment files
- **Automated Backups** - Restic-based backup before every upgrade
- **Standardized Structure** - Consistent patterns across all services
- **CI/CD Tested** - GitHub Actions pipeline validates all configurations

## Quick Start

```bash
# Clone the repository
git clone https://github.com/beevelop/TSHITS.git
cd TSHITS

# Configure your environment
echo "production" > .bee.environ
echo "your-master-password" > .bee.pass

# Deploy a service
cd services/gitlab
cp .env.example .env.production
# Edit .env.production with your settings
./bee up production
```

## Prerequisites

| Tool | Purpose | Installation |
|------|---------|--------------|
| Docker | Container runtime | [docker.com](https://docs.docker.com/get-docker/) |
| Docker Compose | Service orchestration | [docs.docker.com](https://docs.docker.com/compose/install/) |
| envsubst | Template substitution | [command-not-found.com](https://command-not-found.com/envsubst) |
| curl | HTTP health checks | [command-not-found.com](https://command-not-found.com/curl) |
| nc (netcat) | TCP/UDP health checks | [command-not-found.com](https://command-not-found.com/nc) |
| restic | Backup management | [command-not-found.com](https://command-not-found.com/restic) |
| openssl | Secret encryption | [command-not-found.com](https://command-not-found.com/openssl) |

**Optional:** CloudFlare account for DNS-01 Let's Encrypt challenge (used by Traefik).

## Project Structure

```
TSHITS/
├── .bee.environ          # Environment name (e.g., "production")
├── .bee.pass             # Master encryption key
├── meta/
│   ├── bee.sh            # Core helper functions
│   └── checks.sh         # Health check functions
├── housekeeping/
│   ├── encrypt_all.sh    # Encrypt all service environments
│   └── prune_backups.sh  # Prune all service backups
└── services/
    └── <service>/
        ├── bee                   # Service helper script
        ├── docker-compose.yml    # Compose configuration
        ├── .env                  # Version tags (committed)
        ├── .env.<environ>        # Environment secrets (gitignored)
        ├── .env.example          # Example configuration (committed)
        └── data/                 # Persistent data (gitignored)
```

## Usage

Navigate to any service directory and use the `bee` helper:

```bash
cd services/<service>
./bee <command> [environment]
```

### Commands

| Command | Description |
|---------|-------------|
| `up <env>` | Full deployment: prepare, launch, and health check |
| `prepare` | Create folders, generate configs |
| `launch` | Pull images and start containers |
| `health` | Run health checks |
| `backup` | Backup data to `./backups/` via restic |
| `upgrade` | Backup + up (safe upgrade) |
| `logs <env>` | Tail container logs |
| `down` | Stop containers |
| `encrypt <env>` | Encrypt `.env.<env>` to `.enc.env.<env>` |
| `decrypt <env>` | Decrypt `.enc.env.<env>` to `.env.<env>` |
| `nuke` | Remove everything including data (**dangerous**) |

### Example: Deploying GitLab

```bash
cd services/gitlab

# Create environment file from example
cp .env.example .env.production

# Edit with your domain and secrets
vim .env.production

# Deploy
./bee up production

# Check status
./bee health
```

## Available Services

| Service | Description |
|---------|-------------|
| **bitwarden** | Password manager with native apps for all platforms |
| **cabot** | Monitoring and alerts (lightweight PagerDuty alternative) |
| **confluence** | Atlassian documentation and knowledge management |
| **crowd** | Atlassian Single Sign-On (SSO) |
| **dependency-track** | Dependency security and license compliance analysis |
| **directus** | REST API/SDK layer for any database |
| **duckling** | NLP text-to-structured-data parser |
| **gitlab** | Git hosting with built-in CI/CD |
| **graylog** | Log aggregation with Elasticsearch |
| **huginn** | Self-hosted IFTTT/Zapier alternative |
| **jira** | Atlassian project and task management |
| **keycloak** | Authentication provider (OpenID, OAuth, LDAP) |
| **metabase** | Database analytics and dashboards |
| **minio** | S3-compatible object storage |
| **monica** | Personal CRM for managing relationships |
| **mysql** | MySQL database server |
| **nexus** | Sonatype binary repository and package registry |
| **openvpn** | OpenVPN server |
| **phpmyadmin** | MySQL web administration |
| **redash** | Data analysis and visualization |
| **registry** | Private Docker registry |
| **rundeck** | Infrastructure automation and runbook execution |
| **sentry** | Application error tracking and monitoring |
| **shields** | Badge generation service |
| **sonarqube** | Code quality and security analysis |
| **statping** | Status page and uptime monitoring |
| **traefik** | Reverse proxy and load balancer with Let's Encrypt |
| **tus** | Resumable file upload server |
| **weblate** | Translation management platform |
| **zabbix** | Enterprise monitoring solution |

## Configuration

### Environment Files

Each service uses two types of environment files:

**.env** (committed) - Version tags and non-sensitive defaults:
```bash
GITLAB_VERSION=16.0.0
POSTGRES_TAG=15-alpine
```

**.env.example** (committed) - Template for environment-specific secrets:
```bash
SERVICE_DOMAIN=gitlab.example.com
DB_USER=bee
DB_PASS=Swordfish
SMTP_HOST=smtp.example.com
```

**.env.<environ>** (gitignored) - Your actual secrets:
```bash
SERVICE_DOMAIN=gitlab.yourdomain.com
DB_USER=gitlab
DB_PASS=your-secure-password
SMTP_HOST=mail.yourdomain.com
```

### Encryption

Encrypt your environment files for secure storage:

```bash
# Set up master password
echo "your-master-password" > .bee.pass

# Encrypt a service's environment file
cd services/gitlab
./bee encrypt production
# Creates .enc.env.production

# Decrypt when needed
./bee decrypt production
# Restores .env.production
```

Alternatively, use environment variables:
```bash
export BEEPASS="your-master-password"
export ENVIRON="production"
```

### Traefik Integration

All services are pre-configured for Traefik v1 reverse proxy. To set up Traefik:

```bash
cd services/traefik

# Create environment file
cp .env.example .env.production
# Configure your CloudFlare credentials and domain

# Generate traefik.toml from template
envsubst < traefik.toml.tpl > traefik.toml

# Start Traefik
./bee up production
```

Services connect via the `traefik_default` external network and expose themselves using Traefik labels:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.frontend.rule=Host:${SERVICE_DOMAIN}"
  - "traefik.docker.network=traefik_default"
  - "traefik.port=8080"
```

## Backups

Backups are managed via [restic](https://restic.net/) and stored locally in each service's `./backups/` directory.

```bash
# Manual backup
cd services/gitlab
./bee backup

# Upgrade with automatic backup
./bee upgrade production

# Prune old backups (from repo root)
./housekeeping/prune_backups.sh
```

**Note:** Local backups protect against failed upgrades. For disaster recovery, sync backups to remote storage using restic's built-in support for S3, B2, SFTP, and other backends.

## Health Checks

Each service implements health checks in its `bee` script:

```bash
# Check service health
./bee health
```

Available check functions in `meta/checks.sh`:

| Function | Usage |
|----------|-------|
| `check_traefik <host> <expected>` | HTTP check via Traefik |
| `check_curl <url> <expected>` | Direct HTTP check |
| `check_tcp <host> <port>` | TCP port check |
| `check_udp <host> <port>` | UDP port check |
| `check_file <path>` | File existence check |

## CI/CD

The repository includes a GitHub Actions pipeline that:

1. **Validates** all docker-compose.yml files (YAML syntax)
2. **Extracts** and lists all Docker images used
3. **Scans** images for CVEs using Trivy (informational)
4. **Tests** each service with Docker Compose

Services can opt out of CI testing by adding a `.ci-skip` file.

See [.github/CI-CD.md](.github/CI-CD.md) for detailed documentation.

## Notes

- **Placeholder Values:** Examples use `example.com`, `bee` (username), and `Swordfish` (password)
- **Traefik Version:** Uses Traefik v1 (intentional for legacy compatibility)
- **Restart Policy:** All containers use `restart: unless-stopped`
- **Logging Limits:** JSON logging with `max-size: 500k` and `max-file: 50`
- **Docker Compose:** All files use `version: "3"`

## Contributing

Pull requests are welcome! Please:

- Follow existing docker-compose patterns
- Include `.env.example` with placeholder values
- Implement health checks in the `bee` script
- Test with `./bee up test` before submitting

## License

[Apache License 2.0](LICENSE)
