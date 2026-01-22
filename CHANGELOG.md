# Changelog

All notable changes to BeeCompose will be documented in this file.


## [26.1.2](https://github.com/beevelop/BeeCompose/compare/v26.1.1...v26.1.2) (2026-01-22)

### Documentation

* add README files for new services with deployment instructions and configurations ([2db6402](https://github.com/beevelop/BeeCompose/commit/2db64025f07be69527ecd755c6d77c0c549b95fc))

### Maintenance

* **services:** update docker-compose files to set default environment variables and improve service domain handling ([ba8b3b9](https://github.com/beevelop/BeeCompose/commit/ba8b3b96ea93a2cf13e6debadc1d0f51f8dd94f5))

## [26.1.1](https://github.com/beevelop/BeeCompose/compare/v26.1.0...v26.1.1) (2026-01-22)

### CI/CD

* bump actions/checkout from 4 to 6 ([#5](https://github.com/beevelop/BeeCompose/issues/5)) ([13581bf](https://github.com/beevelop/BeeCompose/commit/13581bf3547932483bb3744a4ff32b7c96796c24))
* bump actions/download-artifact from 4 to 7 ([#6](https://github.com/beevelop/BeeCompose/issues/6)) ([094cabc](https://github.com/beevelop/BeeCompose/commit/094cabcdd138ab25990d3aa76845506d3d6d6fe9))
* bump actions/upload-artifact from 4 to 6 ([#3](https://github.com/beevelop/BeeCompose/issues/3)) ([7c00ab2](https://github.com/beevelop/BeeCompose/commit/7c00ab236678f6f98d06c448278a5ddb350517a1))
* bump peter-evans/create-pull-request from 6 to 8 ([#2](https://github.com/beevelop/BeeCompose/issues/2)) ([a6f96e3](https://github.com/beevelop/BeeCompose/commit/a6f96e3b72261f1035a1cf3eaf069dafc4f4c4b7))
* **ci-cd:** enhance bind mount detection and OCI compatibility validation ([b995e23](https://github.com/beevelop/BeeCompose/commit/b995e231f29045bb58fb04a4795f079ab6e61b93))

## 26.1.0 (2026-01-22)

### Features

* **ci-cd:** enhance parallel testing for Docker Compose services and improve result aggregation ([e69ade2](https://github.com/beevelop/BeeCompose/commit/e69ade2d28cbc997a6e8bbf822ac2ab1159aaaa4))
* **ci:** add CI/CD pipeline for docker compose testing and vulnerability scanning ([e98e3ed](https://github.com/beevelop/BeeCompose/commit/e98e3ed42e883aa1ca22432c71f1ed8a3010da91))
* **OCI:** switch to OCI artifacts ([ce61e3b](https://github.com/beevelop/BeeCompose/commit/ce61e3bcdd1d4f956e2294f3ff2978a0fa7bbb53))
* **services:** update docker-compose configurations for multiple services to enhance traefik integration and improve environment variable management ([de60e8d](https://github.com/beevelop/BeeCompose/commit/de60e8d8b10b59a431e1a7b653421898213d64b0))

### Refactoring

* **scripts:** improve handling of environment variables and image extraction in bash scripts ([e654d41](https://github.com/beevelop/BeeCompose/commit/e654d41efef1f20cb9f9f7d1b138884a55396ee6))

### Documentation

* add backup, deployment, naming, and testing guides for BeeCompose services ([e98f2d3](https://github.com/beevelop/BeeCompose/commit/e98f2d3a998e8e846a0a5615a03746bafb2d3e5a))
* **agents:** add comprehensive AI agent operating manual for T-SHITS ([c3820e9](https://github.com/beevelop/BeeCompose/commit/c3820e926eca38b3a0410dccc9d2466764f3ceae))
* **agents:** update Traefik version and enhance linting guidelines ([cb7fa6a](https://github.com/beevelop/BeeCompose/commit/cb7fa6aec2336f1e4d818f5b316644e7f6265079))
* **ci-cd:** update CI/CD documentation to reflect new workflows and OCI publishing details ([2b59d28](https://github.com/beevelop/BeeCompose/commit/2b59d283418684763f9f95d1d88417712247cb04))
* **readme:** update project description and enhance quick start instructions ([dacf77f](https://github.com/beevelop/BeeCompose/commit/dacf77ff3e537763658fe00ec9bb5dcb80b743ce))

### Maintenance

* add .vscode to .gitignore ([489c607](https://github.com/beevelop/BeeCompose/commit/489c607478121ab85fa77877b03c9070fcc71df9))
* add release-it configuration and changelog ([6f42551](https://github.com/beevelop/BeeCompose/commit/6f42551269d332b617c60ff5be7ec7cd3dcf2f21))
* **docs:** update references from T-SHITS to BeeCompose in documentation and configuration files ([0d90a97](https://github.com/beevelop/BeeCompose/commit/0d90a973eedf92ace5da85aecf1337379921bc47))
* **gitlab, minio:** update environment variables for gitlab and minio services ([6ffcb73](https://github.com/beevelop/BeeCompose/commit/6ffcb73d1e644c948553eb7d38e3e353006f2a54))
* **gitlab:** update git port configuration and fix traefik network definition ([efc7ebb](https://github.com/beevelop/BeeCompose/commit/efc7ebb8265dfff12f2c493ab9218003bed895a5))
* **gitlab:** update gitlab port mapping to use default 2222 ([728a4cf](https://github.com/beevelop/BeeCompose/commit/728a4cfcd18bbf918d9335d0cfeebc768e4422c5))
* **services:** add .ci-skip files for nexus and traefik services and update environment variables for weblate ([8554ced](https://github.com/beevelop/BeeCompose/commit/8554ced63c86e65f606d8af1e93b6b4cd025e8f7))
* **services:** update dependency versions and configurations ([f2b753b](https://github.com/beevelop/BeeCompose/commit/f2b753b9a9bef13620b276e79c8162d455db04ba))
* **services:** update docker-compose configurations and environment variables for multiple services ([1471b04](https://github.com/beevelop/BeeCompose/commit/1471b041eaa99400fe3204a81ef5ab2a753946d9))
* **services:** update docker-compose configurations and environment variables for multiple services ([bad25de](https://github.com/beevelop/BeeCompose/commit/bad25de0b07c3ed1b1b1c372dd7c0ebad78a7ea6))
* **services:** update service versions in environment files ([f1b5e41](https://github.com/beevelop/BeeCompose/commit/f1b5e41d157e2bc13110a549fa37dbc0b19702be))
* **services:** update various service versions and configurations ([90535f9](https://github.com/beevelop/BeeCompose/commit/90535f9974b2993764c9382582eb250387433072))
* **traefik:** update network handling and replace traefik.toml with traefik.yml ([9ad287f](https://github.com/beevelop/BeeCompose/commit/9ad287f5a8bfd782ee65d968598bf46ce697ffdf))
* **zabbix:** update environment variables and fix traefik network definition ([00f1ac7](https://github.com/beevelop/BeeCompose/commit/00f1ac7eac7168427e662b27aadb5b0b2d3058e7))

### CI/CD

* add .ci-skip marker for openvpn service and improve service skipping logic ([0b5cf40](https://github.com/beevelop/BeeCompose/commit/0b5cf40634afb6a1f3a282aabadfd854feb3c353))
* add Docker Compose linter configuration and integrate linting step in CI pipeline ([0162e07](https://github.com/beevelop/BeeCompose/commit/0162e07f3a06d2cef6b765674f597ed2cd711739))
* **cve-scan:** enhance CVE scanning with parallel execution and improved result aggregation ([ca0e809](https://github.com/beevelop/BeeCompose/commit/ca0e809ac28c7b3d56bc6de0aa49da3cce2280e2))
* **lint:** improve error and warning count validation in lint results ([ad7ef36](https://github.com/beevelop/BeeCompose/commit/ad7ef361eef5aa66df83371087692aa3bd765bea))
* silence cleanup logs for improved actionable output ([2eaaff2](https://github.com/beevelop/BeeCompose/commit/2eaaff2e941d687d7397384b69c8e458f4552faf))
* update CVE scanning configuration to be non-blocking and improve reporting ([0e58dc6](https://github.com/beevelop/BeeCompose/commit/0e58dc6f460e07deb0c79cd7752ea340c641bfcb))
* update docker compose commands to use quiet mode for reduced log noise ([d810b5e](https://github.com/beevelop/BeeCompose/commit/d810b5e664f9492b73b0485647427e26ba4ebcba))

# Changelog

All notable changes to BeeCompose will be documented in this file.
