# AGENTS.md

AI agent operating manual for T-SHITS. **Read completely before any action.**

---

## Project Overview

**T-SHITS** – The Self-Hosted, Independent Technology Stack.

- **Created:** April 2020
- **Purpose:** Docker-Compose configurations for self-hosted services
- **Reverse Proxy:** Traefik v1 with Let's Encrypt (CloudFlare DNS-01)
- **Encryption:** OpenSSL AES-256-CBC for environment files
- **Backups:** Restic (local `./backups/` per service)

---

## Do

- Follow existing docker-compose patterns exactly
- Use `version: "3"` for all compose files
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
- Pin image versions explicitly (no `latest` except for Redis)

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
- **Never** change Traefik v1 syntax to v2/v3 (legacy stack)

---

## Project Structure

```
TSHITS/
├── .bee.environ          # Environment slug (e.g., "production")
├── .bee.pass             # Master encryption key (NEVER commit real value)
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
envsubst < traefik.toml.tpl > traefik.toml
```

---

## Safety & Permissions

**Allowed without asking:**
- Read files, list directories
- Analyze docker-compose configurations
- Validate YAML syntax
- Create new `.env.example` files

**Ask first:**
- Modifying existing docker-compose.yml files
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

```yaml
version: "3"
services:
  <service>:
    image: <image>:${<SERVICE>_VERSION}
    environment:
      - VAR=${VAR}
    labels:
      - "traefik.enable=true"
      - "traefik.frontend.rule=Host:${SERVICE_DOMAIN}"
      - "traefik.docker.network=traefik_default"
      - "traefik.port=<port>"
    networks: [<service>,traefik]
    volumes: ["./data/<subdir>:/container/path"]
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "500k"
        max-file: "50"

networks:
  <service>:
  traefik:
    external:
      name: traefik_default
```

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
8. Test with `./bee up test`

---

## Updating a Service

1. Update version in `.env` file
2. Check upstream changelog for breaking changes
3. Update `docker-compose.yml` if required
4. Run `./bee upgrade <environ>` (creates backup first)
5. Verify with `./bee health`
6. Commit with format: `<Service>: <version>`

---

## Prerequisites Reference

| Tool | Purpose |
|------|---------|
| Docker | Container runtime |
| Docker-Compose | Service orchestration |
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
- Validate YAML syntax before testing
- Check Traefik dashboard at `:8080` for routing issues

---

**Keep it simple. Keep it self-hosted. Keep it running.**
