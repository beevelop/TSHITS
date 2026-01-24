# AGENTS.md

AI agent operating manual for BeeCompose. **Read completely before any action.**

---

## Project Overview

**BeeCompose** – Production-ready Docker Compose stacks. Curated.

- **Created:** April 2020
- **Purpose:** Docker-Compose configurations for self-hosted services
- **Distribution:** OCI artifacts published to GitHub Container Registry
- **Reverse Proxy:** Traefik v3 with Let's Encrypt (CloudFlare DNS-01) or Cloudflare Tunnel
- **Linting:** DCLint (zavoloklom/docker-compose-linter) for compose file validation

---

## Do

- Follow existing docker-compose patterns exactly
- Use `name: <service>` to explicitly set the project name (do NOT use `version` - it is obsolete)
- Include `restart: unless-stopped` on all containers
- Add JSON logging limits to every service:
  ```yaml
  logging:
    driver: "json-file"
    options:
      max-size: "500k"
      max-file: "50"
  ```
- Connect services to Traefik via external network `traefik_default`
- Use environment variable substitution (`${VAR}`) in compose files
- Place service-specific configs in the service directory
- Embed version tags as default values directly in docker-compose.yml (e.g., `image: nginx:${NGINX_VERSION:-1.25.3}`) for OCI compatibility
- Use `.env` for version tags, `.env.example` for configuration templates
- Use `example.com` as placeholder domain in examples
- Use `Swordfish` as placeholder password in examples
- Pin image versions explicitly (see Image Tagging Policy below)
- Use explicit interface binding for ports (e.g., `"0.0.0.0:80:80"`)
- Run DCLint before submitting compose file changes

## Don't

- **Never** execute docker-compose commands locally (`docker-compose up`, `docker-compose down`, `docker-compose pull`, etc.)
- **Never** commit real secrets, credentials, or API keys
- **Never** run destructive commands (`down --volumes`) without explicit approval
- **Never** run git write operations (`git commit`, `git push`, `git merge`)

---

## Image Tagging Policy

Pin image versions explicitly to ensure reproducible deployments.

**Standard Rule:** Use explicit version tags (e.g., `nginx:1.25.3`, `postgres:15-alpine`)

**Allowed Exceptions:**
- **Redis:** May use `latest` tag (stable, backward-compatible)
- **Images with only `latest` available:** Document with comment in docker-compose.yml explaining the exception

**Example for exception:**
```yaml
# docker-compose.yml
# Note: redash/nginx only publishes 'latest' tag - no versioned tags available
image: redash/nginx:${REDASH_NGINX_VERSION:-latest}
```

---

## Linting

Docker Compose files are validated using [DCLint](https://github.com/zavoloklom/docker-compose-linter).

### Running the Linter

```bash
# Validate all compose files (read-only)
docker run --rm -v "$(pwd):/app" zavoloklom/dclint:latest /app/services -r -c /app/.dclintrc.yaml

# Auto-fix style issues (formatting, ordering)
docker run --rm -v "$(pwd):/app" zavoloklom/dclint:latest /app/services -r -c /app/.dclintrc.yaml --fix
```

### Linter Rules

Configuration is in `.dclintrc.yaml`. Key rules enforced:

| Rule | Level | Description |
|------|-------|-------------|
| `no-quotes-in-volumes` | Error | Volume paths must not be quoted |
| `require-quotes-in-ports` | Error | Port mappings must use double quotes |
| `service-image-require-explicit-tag` | Error | Images must have explicit tags |
| `no-duplicate-container-names` | Error | Container names must be unique |
| `no-duplicate-exported-ports` | Error | Exported ports must be unique |
| `require-project-name-field` | Error | Compose files must have `name` field |
| `no-unbound-port-interfaces` | Error | Ports must specify interface (0.0.0.0) |
| `service-keys-order` | Warning | Service keys should follow standard order |
| `services-alphabetical-order` | Warning | Services should be alphabetically sorted |

### CI/CD Integration

The linter runs automatically in the CI/CD pipeline (Job 1). All errors must be fixed before merging.

---

## Project Structure

```
beecompose/
├── .dclintrc.yaml        # Docker Compose linter configuration
├── .github/
│   ├── workflows/        # CI/CD pipelines
│   └── scripts/          # Test and validation scripts
├── docs/
│   ├── BACKUP.md         # Backup procedures
│   ├── DEPLOYMENT.md     # Deployment guide
│   └── TESTING.md        # Testing procedures
├── scripts/
│   ├── bc                    # CLI helper (optional, install system-wide)
│   ├── install.sh            # bc CLI installer
│   ├── publish-dry-run.sh    # OCI publishing dry run
│   ├── test-oci.sh           # Test OCI deployment
│   └── validate-all-oci.sh   # Validate OCI compatibility
└── services/
    └── <service>/
        ├── docker-compose.yml    # Compose configuration (versions as defaults)
        ├── README.md             # Service documentation
        ├── .env                  # Version tags (committed)
        ├── .env.example          # Example config (committed)
        └── .env.<environ>        # Environment secrets (gitignored)
```

---

## Common Operations

### bc CLI Helper (Optional)

The `bc` CLI simplifies OCI artifact deployment. **Usage is optional** - direct `docker compose` commands work equally well.

```bash
# Install bc CLI (optional)
curl -fsSL https://raw.githubusercontent.com/beevelop/beecompose/main/scripts/install.sh | sudo bash

# Deploy service
bc <service> up        # Starts service, always pulls latest
bc <service> down      # Stops service
bc <service> logs -f   # Follow logs
bc <service> ps        # Check status
bc <service> update    # Pull and recreate

# Pin OCI version
bc init v26.1.6        # Creates .beecompose config
bc -v latest sentry up # Override version per-command
```

The bc CLI:
- Wraps `docker compose -f oci://...` with opinionated defaults
- Always pulls latest images (`--pull always`)
- Automatically uses `.env.<service>` for environment variables
- Supports version pinning via `.beecompose` file or `-v` flag

> **Note:** When documenting services, always show both bc CLI and manual docker compose commands.

### Deploying from OCI Artifact (Manual)

```bash
# Deploy directly from GHCR
docker compose -f oci://ghcr.io/beevelop/<service>:latest --env-file .env up -d

# View logs
docker compose -f oci://ghcr.io/beevelop/<service>:latest --env-file .env logs -f

# Stop service
docker compose -f oci://ghcr.io/beevelop/<service>:latest --env-file .env down
```

### Local Development

```bash
cd services/<service>

# Deploy locally
docker compose --env-file .env.example up -d

# View logs
docker compose logs -f

# Stop
docker compose down
```

### Validation Scripts

```bash
# Validate single service for OCI compatibility
./scripts/publish-dry-run.sh <service>

# Validate all services
./scripts/validate-all-oci.sh

# Test OCI artifact deployment
./scripts/test-oci.sh <service> [version]
```

---

## Safety & Permissions

**Allowed without asking:**
- Read files, list directories
- Analyze docker-compose configurations
- Validate YAML syntax
- Create new `.env.example` files
- Run DCLint in read-only mode (validation only)
- Apply DCLint auto-fixes for style issues (formatting, key ordering)

**Ask first:**
- Modifying existing docker-compose.yml files (beyond lint fixes)
- Adding new services
- Modifying CI/CD workflows

**Never do (require explicit confirmation):**
- Execute any docker-compose commands locally
- Any git write operations

---

## Docker-Compose Patterns

### Standard Service Template

Service keys must follow DCLint's expected order:

```yaml
name: <service>
services:
  <service>:
    image: <image>:${<SERVICE>_VERSION:-1.2.3}
    container_name: <service>
    depends_on: [dependency1, dependency2]
    volumes:
      - <service>_data:/container/path
    environment:
      - VAR=${VAR}
    ports:
      - "0.0.0.0:8080:8080"
    networks: [<service>, traefik]
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "500k"
        max-file: "50"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.<service>.rule=Host(`${SERVICE_DOMAIN}`)"
      - "traefik.http.routers.<service>.entrypoints=websecure"
      - "traefik.http.services.<service>.loadbalancer.server.port=<port>"
      - "traefik.docker.network=traefik_default"

volumes:
  <service>_data:

networks:
  <service>:
  traefik:
    external:
      name: traefik_default
```

> **TLS Note:** Do NOT include `tls=true` or `tls.certresolver` labels. TLS is configured at the Traefik entrypoint level, enabling services to work in both exposed (Let's Encrypt) and tunnel (Cloudflare) modes without modification.

> **OCI Note:** Use named volumes (not bind mounts) for OCI artifact compatibility.

### Service Key Order Reference

When defining services, use this key order for consistency:

1. `image`
2. `build`
3. `container_name`
4. `depends_on`
5. `volumes`
6. `volumes_from`
7. `configs`
8. `secrets`
9. `environment`
10. `env_file`
11. `ports`
12. `networks`
13. `network_mode`
14. `extra_hosts`
15. `command`
16. `entrypoint`
17. `working_dir`
18. `restart`
19. `healthcheck`
20. `logging`
21. `labels`
22. `user`
23. `isolation`

### Environment File Patterns

**.env (committed) - Version tags only:**
```bash
SERVICE_VERSION=1.2.3
POSTGRES_TAG=17-alpine
```

**.env.example (committed) - Configuration template:**
```bash
SERVICE_DOMAIN=service.example.com
DB_USER=bee
DB_PASS=Swordfish
SECRET_KEY=your_secret_here
```

### Traefik v3 Labels Reference

All services use Traefik v3 label syntax for routing configuration. TLS is handled at the entrypoint level, NOT in service labels:

| Label | Purpose |
|-------|---------|
| `traefik.enable=true` | Enable Traefik for this container |
| `traefik.http.routers.<name>.rule=Host(\`domain\`)` | Route by hostname (use backticks!) |
| `traefik.http.routers.<name>.entrypoints=websecure` | Use HTTPS entrypoint |
| `traefik.http.services.<name>.loadbalancer.server.port=<port>` | Container port to route to |
| `traefik.docker.network=traefik_default` | Docker network for routing |

**Important:** 
- The `<name>` in router/service labels should match the service/container name for consistency
- Do NOT use `tls=true` or `tls.certresolver` labels - TLS is configured at the Traefik entrypoint level to support both exposed (Let's Encrypt) and tunnel (Cloudflare) modes

---

## Commit Message Format

```
<Service>: <Description>

# Examples:
GitLab: 13.5.3
MetaBase: v0.36.4
Sentry: Update base image to getsentry/sentry
```

- Use service name as prefix
- Include version number for upgrades
- Reference issues with `(close #123)` when applicable

---

## Adding a New Service

1. Create `services/<name>/` directory
2. Create `docker-compose.yml` following the standard template (with version defaults embedded)
3. Create `.env` with version tags
4. Create `.env.example` with placeholder secrets
5. Create `README.md` with deployment instructions
6. Use named volumes (no bind mounts for OCI compatibility)
7. Run DCLint to validate: `docker run --rm -v "$(pwd):/app" zavoloklom/dclint:latest /app/services/<name> -c /app/.dclintrc.yaml`

---

## Updating a Service

1. Update version in `.env` file
2. Update version default in `docker-compose.yml` image tag
3. Check upstream changelog for breaking changes
4. Update `docker-compose.yml` if required
5. Run DCLint to validate changes
6. Update `README.md` if configuration changed
7. Commit with format: `<Service>: <version>`

---

## Prerequisites Reference

| Tool | Purpose |
|------|---------|
| Docker 25.0+ | Container runtime with OCI support |
| Docker Compose v2.24+ | Service orchestration |
| DCLint | Docker Compose linting (via Docker image) |

---

## When Stuck

- Reference existing services as examples (GitLab, Sentry are comprehensive)
- Run DCLint to validate compose syntax
- Check service README for configuration details
- Run `./scripts/validate-all-oci.sh` to check OCI compatibility

---

**Keep it simple. Keep it self-hosted. Keep it running.**
