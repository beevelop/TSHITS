# T-SHITS 👕💩
## The Self-Hosted, Independent Technology Stack 

Around 4 years ago, I started developing and maintaining my personal, self-hosted technology stack and wrote a bunch of Docker-Compose files. I wanted to host awesome tools like GitLab, Metabase, Jira, Huginn, Monica, Bitwarden, Cabot, Confluence, OpenVPN, Nexus, Redash, Rundeck, Weblate, Zabbix and even more on my own infrastructure.

In the light of the [recent announcement](https://www.docker.com/blog/announcing-the-compose-specification/) from Docker to develop the **Compose Specification**, I like to contribute **T**he **S**elf-**H**osted, **I**ndependent **T**echnology **S**tack (pronounced **T-SHITS**) to the community.

> :warning: Some of the Docker-Compose files are over 2 years old and might not work with the most recent versions of the referenced Docker images. Feel free to raise an issue, if you stumble upon something. :v:

## Prerequisites
Make sure you have Docker and Docker-Compose installed on your machine. By
default the T-SHITS stack uses Traefik and the DNS-01 challenge with CloudFlare
to get Let's Encrypt certificates. So CloudFlare can be considered an optional
prerequisite.

- For Traefik you need to have `envsubst` [installed (see installation
  instructions)](https://command-not-found.com/envsubst).
- For healthchecks you need to have [`curl`](https://command-not-found.com/curl)
  and [`nc`](https://command-not-found.com/nc) installed.
- For backups (automatically executed before upgrades)
  [`restic`](https://command-not-found.com/restic) is being used.
- [`OpenSSL`](https://command-not-found.com/openssl) is used to encrypt /
  decrypt ENV files.

## Installation

To use the services and start spinning up your own T-SHITS services, you just need to clone (or fork if you like to) this repo:
```bash
git clone https://github.com/beevelop/TSHITS.git
```

### Configuring an environment (optionally with encryption)
1. Create a `.bee.pass` file inside the T-SHITS root folder containing the environment's master key / pass (e.g. `Swordfish`).
2. Create a `.bee.environ` file inside the T-SHITS root folder containing the environment's slug (e.g. `foobar`).

Alternatively you can set both configurations using normal ENVs: `BEEPASS` and
`ENVIRON`. The encryption uses `openssl aes-256-cbc` to encrypt / decrypt the
values in the respective `.env.example` file.

## Usage

Every service has a helper `./bee.sh` file. Just navigate to your favorite service and execute one of the helper functions:
```
Usage: ./bee COMMAND [options]

Commands:
    prepare   Prepares the service for launch (e.g. folders, files, configs,...)
    launch    Launches the service (overwrite with do_launch)
    health    Checks if the service is running properly
    up [ENV]  Prepares, launches and checks the service for the provided ENV

Helpers:
    encrypt [ENV]  Encrypts the .env file for the provided ENV
    decrypt [ENV]  Decrypts the .env file for the provided ENV
    upgrade   Upgrade a service (combines backup and up)

DANGERZONE (don't mess with this shit... seriously):
    nuke      Kills the service and removes all traces (image, files, configs,...)
```

```bash
# navigate to the service's subfolder
cd services/gitlab

# check the .env and .env.example (and other env files)
# customize them to your needs and please swap the default
# passwords / secrets / ...
cp .env.example .env.foobar

# foobar is the name of the environment
./bee up foobar
```

## Architecture
All services have an individual `.env` file to manage the "general" ENVs (like
Docker image version, etc.). Additionally there is `.env.example` for every
environment you want to manage. They contain environment specific
configurations. One standard ENV (that is being used in the `bee.sh` helper) is
the `SERVICE_DOMAIN` which is most often used to expose the services via
Traefik.

T-SHITS stack uses Traefik by default and all services are configured to work
with Traefik **v1**.

## Services
- **Bitwarden**: Self-hosted password manager with native apps for all major operating systems.
- **Cabot**: Self-hosted, easily-deployable monitoring and alerts service - like a lightweight PagerDuty
- **Confluence**: Atlassian's well-known documentation and knowledge management software.
- **crowd**: Atlassian's Single Sign-On (SSO) solution
- **Dependency-Track**: Analyse your dependencies for Security issues and license compliance.
- **Directus**: Quickly put a REST-API / SDK on top of your database.
- **Duckling**: Quite specific for NLP-enthusiast, but it enables you to parse text into structured data.
- **Gitlab**: Host your own VCS and CI / CD environment through GitLab.
- **Graylog**: In combination with Elasticsearch it enables you to log any kind of data. Most often used for log aggregation.
- **Huginn**: The self-hosted alternative to things like IFTTT or Zapier.
- **Jira**: Atlassian's task / project / everything management monster (meant in a positive way 😉).
- **Keycloak**: Your own authentication / authorization provider. With OpenID, OAuth, LDAP and ActiveDirectory support.
- **Metabase**: Analyse any kind of database and build beautiful dashboards. Makes SQL-queries accessible to non-techies.
- **Minio**: Self-hosted S3 alternative.
- **Monica**: Personal CRM to remember staying in touch with the people you like (but sometimes forget).
- **MySQL**: Good ol' MySQL database
- **Nexus**: Sonatype's Nexus can be used as binary store, self-hosted package registry, etc.
- **OpenVPN**: Your own OpenVPN to secure your connection.
- **PHPMyAdmin**: Enables you to administer MySQL databases through an easy UI.
- **Redash**: Similar to Metbase (enables you to analyze data), but a bit more "technical".
- **Registry**: Host your own Docker registry.
- **Rundeck**: Automate all the things. The "CI / CD for infrastructure that is not involved in the development process".
- **Sentry**: Log all exceptions / errors in your application / services / ... (e.g. you can log GitLab exceptions to Sentry too)
- **Shields**: Self-hosted version to get beautiful badges for your repositories.
- **Sonarqube**: Analyze your development sources.
- **Statping**: Status Page & Monitoring Server
- **Traefik**: Load-balancer / reverse-proxy and "certificate manager" in the case of **T-SHITS**.
- **Tus**: Upload services on steroids.
- **Weblate**: Translate all the things with Weblate.
- **Zabbix**: High-end monitoring for everything with a nice UI.

## Notes
- Most services use `example.com`, `smtp.example.com`, `bee` (username) or
  `Swordfish` (dummy password) as example values. All tokens / API keys, etc.
  are in the respective format (length / the way they where generated).
- Backups are stored in the **local** folder `./backup` of each services.
  Consider it a simple example to recover from a failed upgrade. You backups
  should usually be synced to a different store / machine to make sure you won't
  loose the data. Restic has great support for different storage providers.
- All services are configure to use the restart policy `unless-stopped`. This
  way containers should stay up if the fail and should start automatically if
  the host system restarts.
- Every service has a logging limit (JSON logging) configured. This way your
  hard drive should not run out of disk space if a service decides to run into a
  logging rampage.
- Most of the services already use Docker volumes. They are preferred over local
  volume mounts.

## Contributing
Pull requests are highly welcomed. Feel free to keep the images up-to-date, add
new configuration capabilities, introduce service specific READMEs and notes.
Just spread the love of using simple Docker-Compose files ❤️
