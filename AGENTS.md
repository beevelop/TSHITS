# AGENTS.md

AI agent operating manual for BeeCompose. **Read completely before any action.**

---

## Project Overview

**BeeCompose** – Production-ready Docker Compose stacks. Curated.

- **Created:** April 2020
- **Purpose:** Docker-Compose configurations for self-hosted services
- **Reverse Proxy:** Traefik v3 with Let's Encrypt (CloudFlare DNS-01)
- **Encryption:** OpenSSL AES-256-CBC for environment files
- **Backups:** Restic (local `./backups/` per service)
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
- Keep `.env` for version tags, `.env.<environ>` for environment-specific secrets
- Use `example.com` as placeholder domain in examples
- Use `Swordfish` as placeholder password in examples
- Pin image versions explicitly (see Image Tagging Policy below)
- Use explicit interface binding for ports (e.g., `"0.0.0.0:80:80"`)
- Run DCLint before submitting compose file changes

## Don't

- **Never** execute docker-compose commands locally (`docker-compose up`, `docker-compose down`, `docker-compose pull`, etc.)
- **Never** run `./bee` commands locally — all testing via GitHub Actions and CI/CD only
- **Never** commit real secrets, credentials, or API keys
- **Never** run destructive commands (`nuke`, `down --volumes`) without explicit approval
- **Never** modify `.bee.pass` or `.bee.environ` files
- **Never** run git write operations (`git commit`, `git push`, `git merge`)
- **Never** execute `./bee upgrade` or `./bee nuke` without user confirmation
- **Never** modify `meta/bee.sh` or `meta/checks.sh` without explicit approval
- **Never** remove backup folders or prune backups without approval

---

## Image Tagging Policy

Pin image versions explicitly to ensure reproducible deployments.

**Standard Rule:** Use explicit version tags (e.g., `nginx:1.25.3`, `postgres:15-alpine`)

**Allowed Exceptions:**
- **Redis:** May use `latest` tag (stable, backward-compatible)
- **Images with only `latest` available:** Document in `.env` file with comment explaining the exception

**Example for exception:**
```bash
# .env
# Note: redash/nginx only publishes 'latest' tag - no versioned tags available
REDASH_NGINX_VERSION=latest
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
├── .bee.environ          # Environment slug (e.g., "production")
├── .bee.pass             # Master encryption key (NEVER commit real value)
├── .dclintrc.yaml        # Docker Compose linter configuration
├── meta/
│   ├── bee.sh            # Core helper functions (DO NOT MODIFY)
│   └── checks.sh         # Health check functions
├── housekeeping/
│   ├── encrypt_all.sh    # Encrypt all service envs
│   └── prune_backups.sh  # Prune all service backups
└── services/
    └── <service>/
        ├── bee                   # Service helper script
        ├── docker-compose.yml    # Compose configuration
        ├── .env                  # Version tags (committed)
        ├── .env.<environ>        # Environment secrets (gitignored)
        ├── .env.example          # Example config (committed)
        └── data/                 # Persistent data (gitignored)
```

---

## Commands

### Service Operations (from `services/<service>/`)

```bash
# Prepare and launch service
./bee up <environ>

# Individual steps
./bee prepare              # Create folders, generate configs
./bee launch               # Pull images and start containers
./bee health               # Run health checks

# Maintenance
./bee backup               # Backup data/ to ./backups/ via restic
./bee upgrade              # Backup + up (ASK FIRST)
./bee logs <environ>       # Tail container logs
./bee down                 # Stop containers (ASK FIRST)
./bee nuke                 # Remove everything (DANGEROUS - ASK FIRST)

# Encryption
./bee encrypt <environ>    # Encrypt .env.<environ> to .enc.env.<environ>
./bee decrypt <environ>    # Decrypt .enc.env.<environ> to .env.<environ>
```

### Housekeeping (from repo root)

```bash
# Encrypt all environments
./housekeeping/encrypt_all.sh <environ>

# Prune all backups (ASK FIRST)
./housekeeping/prune_backups.sh
```

### Traefik Setup (from `services/traefik/`)

```bash
# Generate config from template
envsubst < traefik.yml.tpl > traefik.yml
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
- Creating encrypted environment files

**Never do (require explicit confirmation):**
- Execute any docker-compose commands locally
- Execute any `./bee` commands locally
- `./housekeeping/prune_backups.sh`
- Modifying `meta/` files
- Any git write operations

---

## Docker-Compose Patterns

### Standard Service Template

Service keys must follow DCLint's expected order:

```yaml
name: <service>
services:
  <service>:
    image: <image>:${<SERVICE>_VERSION}
    container_name: <service>
    depends_on: [dependency1, dependency2]
    volumes:
      - ./data/<subdir>:/container/path
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

networks:
  <service>:
  traefik:
    external:
      name: traefik_default
```

> **TLS Note:** Do NOT include `tls=true` or `tls.certresolver` labels. TLS is configured at the Traefik entrypoint level, enabling services to work in both exposed (Let's Encrypt) and tunnel (Cloudflare) modes without modification.

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

**.env (committed):**
```bash
SERVICE_VERSION=1.2.3
POSTGRES_TAG=13-alpine
```

**.env.example (committed):**
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

## Service Bee Script Pattern

```bash
#!/usr/bin/env bash

export SERVICE="ServiceName"
export WAIT_TIME=20

do_health() {
  STATUS=0
  check_traefik ${SERVICE_DOMAIN} "HTTP/1.1 200 OK" || STATUS=$?
  return $STATUS
}

do_prepare() {
  echo "Creating data directories..."
  mkdir -p ./data/subfolder
}

. ../../meta/bee.sh "${@}"
```

### Available Health Check Functions

```bash
check_traefik <host> <expected>  # Check via Traefik (e.g., "HTTP/1.1 302 Found")
check_curl <url> <expected>      # Direct HTTP check
check_tcp <host> <port>          # TCP port check
check_udp <host> <port>          # UDP port check
check_file <path>                # File existence check
```

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
2. Create `docker-compose.yml` following the standard template
3. Create `.env` with version tags
4. Create `.env.example` with placeholder secrets
5. Create `bee` script with `SERVICE` and `WAIT_TIME` exports
6. Implement `do_health()` function
7. Optionally implement `do_prepare()` for setup tasks
8. Run DCLint to validate: `docker run --rm -v "$(pwd):/app" zavoloklom/dclint:latest /app/services/<name> -c /app/.dclintrc.yaml`
9. Test with `./bee up test`

---

## Updating a Service

1. Update version in `.env` file
2. Check upstream changelog for breaking changes
3. Update `docker-compose.yml` if required
4. Run DCLint to validate changes
5. Run `./bee upgrade <environ>` (creates backup first)
6. Verify with `./bee health`
7. Commit with format: `<Service>: <version>`

---

## Prerequisites Reference

| Tool | Purpose |
|------|---------|
| Docker | Container runtime |
| Docker-Compose | Service orchestration |
| DCLint | Docker Compose linting (via Docker image) |
| envsubst | Template substitution (Traefik config) |
| curl | HTTP health checks |
| nc | TCP/UDP health checks |
| restic | Backup management |
| openssl | Environment encryption |

---

## When Stuck

- Check `meta/bee.sh` for available helper functions
- Check `meta/checks.sh` for health check implementations
- Reference existing services as examples (GitLab, Sentry are comprehensive)
- Run DCLint to validate compose syntax
- Check Traefik dashboard at `:8080` for routing issues

---

**Keep it simple. Keep it self-hosted. Keep it running.**
