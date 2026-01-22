# Backup Guide

This guide covers backup and restore procedures for BeeCompose services using Docker named volumes.

## Overview

All BeeCompose services use Docker named volumes for persistent data. This ensures data is:
- Managed by Docker (not tied to host paths)
- Portable across environments
- Compatible with OCI artifact deployment

## Identify Service Volumes

List all volumes for a specific service:

```bash
# List volumes by project name
docker volume ls --filter "name=gitlab"

# Example output:
# DRIVER    VOLUME NAME
# local     gitlab_app_data
# local     gitlab_postgres_data
# local     gitlab_redis_data
```

## Backup Methods

### Method 1: Tar Archive (Simple)

Best for: Quick backups, single volumes, development environments.

```bash
# Backup a single volume
docker run --rm \
  -v gitlab_postgres_data:/data:ro \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/gitlab_postgres_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .

# Backup all volumes for a service
for vol in $(docker volume ls -q --filter "name=gitlab"); do
  docker run --rm \
    -v ${vol}:/data:ro \
    -v $(pwd)/backups:/backup \
    alpine tar czf /backup/${vol}_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
done
```

### Method 2: Database-Specific Dumps

Best for: Databases (PostgreSQL, MySQL, MongoDB). Provides consistent, application-aware backups.

#### PostgreSQL

```bash
# Dump database
docker compose exec postgres pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} > backup.sql

# Dump with compression
docker compose exec postgres pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} | gzip > backup.sql.gz

# Restore
cat backup.sql | docker compose exec -T postgres psql -U ${POSTGRES_USER} ${POSTGRES_DB}
```

#### MySQL

```bash
# Dump database
docker compose exec mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} > backup.sql

# Dump all databases
docker compose exec mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} --all-databases > all_databases.sql

# Restore
cat backup.sql | docker compose exec -T mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE}
```

#### MongoDB

```bash
# Dump database
docker compose exec mongodb mongodump --out /backup

# Copy from container
docker cp $(docker compose ps -q mongodb):/backup ./mongodb_backup

# Restore
docker cp ./mongodb_backup $(docker compose ps -q mongodb):/backup
docker compose exec mongodb mongorestore /backup
```

#### Redis

```bash
# Trigger RDB save
docker compose exec redis redis-cli BGSAVE

# Copy RDB file
docker cp $(docker compose ps -q redis):/data/dump.rdb ./redis_backup.rdb

# Restore (replace file before starting)
docker cp ./redis_backup.rdb $(docker compose ps -q redis):/data/dump.rdb
docker compose restart redis
```

### Method 3: Restic (Production)

Best for: Production environments, scheduled backups, remote storage, deduplication.

```bash
# Initialize repository (first time only)
docker run --rm \
  -v restic_repo:/repo \
  -e RESTIC_PASSWORD=your_secure_password \
  restic/restic init -r /repo

# Backup a volume
docker run --rm \
  -v gitlab_postgres_data:/data:ro \
  -v restic_repo:/repo \
  -e RESTIC_PASSWORD=your_secure_password \
  restic/restic -r /repo backup /data --tag gitlab --tag postgres

# List snapshots
docker run --rm \
  -v restic_repo:/repo \
  -e RESTIC_PASSWORD=your_secure_password \
  restic/restic -r /repo snapshots

# Restore from snapshot
docker run --rm \
  -v gitlab_postgres_data:/data \
  -v restic_repo:/repo \
  -e RESTIC_PASSWORD=your_secure_password \
  restic/restic -r /repo restore latest --target /data --tag postgres
```

#### Restic with S3/MinIO

```bash
# Backup to S3-compatible storage
docker run --rm \
  -v gitlab_postgres_data:/data:ro \
  -e RESTIC_PASSWORD=your_secure_password \
  -e AWS_ACCESS_KEY_ID=your_key \
  -e AWS_SECRET_ACCESS_KEY=your_secret \
  restic/restic -r s3:https://s3.example.com/bucket/path backup /data
```

## Restore Procedures

### Restore Tar Archive

```bash
# Stop the service first
docker compose down

# Clear existing volume (if needed)
docker volume rm gitlab_postgres_data
docker volume create gitlab_postgres_data

# Restore from backup
docker run --rm \
  -v gitlab_postgres_data:/data \
  -v $(pwd)/backups:/backup:ro \
  alpine tar xzf /backup/gitlab_postgres_20240121_120000.tar.gz -C /data

# Start service
docker compose up -d
```

### Restore Database Dump

```bash
# Start only database container
docker compose up -d postgres

# Wait for database to be ready
sleep 10

# Restore dump
cat backup.sql | docker compose exec -T postgres psql -U ${POSTGRES_USER} ${POSTGRES_DB}

# Start remaining services
docker compose up -d
```

## Automated Backup Script

Create `backup.sh` in your service directory:

```bash
#!/bin/bash
set -euo pipefail

SERVICE="${1:-$(basename $(pwd))}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "=== Backing up ${SERVICE} ==="

# Backup all volumes for this project
for vol in $(docker volume ls -q --filter "name=${SERVICE}"); do
  echo "Backing up volume: ${vol}"
  docker run --rm \
    -v ${vol}:/data:ro \
    -v $(pwd)/${BACKUP_DIR}:/backup \
    alpine tar czf /backup/${vol}_${DATE}.tar.gz -C /data .
done

echo "=== Backup complete ==="
ls -lh "$BACKUP_DIR"/*_${DATE}.tar.gz
```

## Backup Schedule Recommendations

| Data Type | Frequency | Retention |
|-----------|-----------|-----------|
| Databases | Daily | 30 days |
| Application data | Daily | 14 days |
| Configuration | Weekly | 90 days |
| Full system | Weekly | 4 weeks |

## Pre-Upgrade Backup

Always backup before upgrading a service:

```bash
# 1. Create backup
./backup.sh

# 2. Pull new images
docker compose pull

# 3. Upgrade
docker compose up -d

# 4. Verify health
docker compose ps
```

## Disaster Recovery Checklist

1. **Verify backups exist and are readable**
   ```bash
   ls -la backups/
   tar tzf backups/latest.tar.gz | head
   ```

2. **Test restore procedure** (on staging first)

3. **Document recovery steps** for each service

4. **Store backups off-site** (S3, remote server, etc.)

5. **Encrypt sensitive backups**
   ```bash
   gpg --symmetric --cipher-algo AES256 backup.tar.gz
   ```

## Service-Specific Notes

### GitLab

GitLab has built-in backup functionality:

```bash
docker compose exec gitlab bundle exec rake gitlab:backup:create
```

Backups are stored in `/home/git/data/backups/` (mapped to `gitlab_app_data` volume).

### Sentry

Use Sentry's export command:

```bash
docker compose exec sentry sentry export > sentry_backup.json
```

### Databases with Replication

For replicated databases, always backup from the primary node to ensure consistency.
