# Traefik v3 Configuration
# Generated from template - use envsubst to create traefik.yml:
#   envsubst < traefik.yml.tpl > traefik.yml

# Global settings
global:
  checkNewVersion: false
  sendAnonymousUsage: false

# API and Dashboard
api:
  dashboard: true
  insecure: false

# Entrypoints
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt
  traefik:
    address: ":8080"

# Providers
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: traefik_default
    watch: true

# TLS Certificate Resolvers
certificatesResolvers:
  letsencrypt:
    acme:
      email: "${TRAEFIK_EMAIL}"
      storage: "/etc/traefik/acme/acme.json"
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"
        delayBeforeCheck: 10s

# Logging
log:
  level: ERROR

# Access log (optional - uncomment if needed)
# accessLog:
#   filePath: "/etc/traefik/logs/access.log"
