# T-SHITS 👕💩
## The Self-Hosted, Independent Technology Stack 

Around 4 years ago, I started developing and maintaining my personal, self-hosted technology stack and wrote a bunch of Docker-Compose files. I wanted to host awesome tools like GitLab, Metabase, Jira, Huginn, Monica, Bitwarden, Cabot, Confluence, OpenVPN, Nexus, Redash, Rundeck, Weblate, Zabbix and even more on my own infrastructure.

In the light of the [recent announcement](https://www.docker.com/blog/announcing-the-compose-specification/) from Docker to develop the **Compose Specification**, I like to contribute **T**he **S**elf-**H**osted, **I**ndependent **T**echnology **S**tack to the community.

> :warning: Some of the Docker-Compose files are over 2 years old and might not work with the most recent versions of the referenced Docker images. Feel free to raise an issue, if you stumble upon something. :v:

## Prerequisites
Make sure you have Docker and Docker-Compose installed on your machine.

## Installation

To use the services and start spinning up your own T-SHITS services, you just need to clone (or fork if you like to) this repo:
```
git clone https://github.com/beevelop/TSHITS.git
```

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
- **Taiga**: Light-weight / modern alternative to Jira
- **Traefik**: Load-balancer / reverse-proxy and "certificate manager" in the case of **T-SHITS**.
- **Tus**: Upload services on steroids.
- **Watchmen**: Watch out for Watchmen... (unfortunately not longer maintained).
- **Weblate**: Translate all the things with Weblate.
- **Weinre**: "Back then" the way to debug e.g. Apache Cordova apps (no longer maintained, if you still use it, have a look at Flutter)
- **Zabbix**: High-end monitoring for everything with a nice UI.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
