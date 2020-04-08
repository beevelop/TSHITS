graceTimeOut = 10
# debug = false
checkNewVersion = false
logLevel = "ERROR"
ProvidersThrottleDuration = 5
defaultEntryPoints = ["http", "https"]

# [accessLog]
# filePath = "/etc/traefik/logs/access.log"

[acme]
email = "${TRAEFIK_EMAIL}"
storageFile = "/etc/traefik/acme/acme.json"
entryPoint = "https"
dnsProvider = "cloudflare"
onDemand = true
OnHostRule = true

[entryPoints]
  [entryPoints.http]
  address = ":80"
  compress = false
   [entryPoints.http.redirect]
      entryPoint = "https"
  [entryPoints.https]
  address = ":443"
  compress = false
    [entryPoints.https.tls]
      [[entryPoints.https.tls.certificates]]
      CertFile = "/certs/traefik.crt"
      KeyFile = "/certs/traefik.key"

[web]
address = ":8080"
  [web.auth.basic]
    # test:test and test2:test2
    users = ["${TRAEFIK_AUTH}"]

[docker]
endpoint = "unix:///var/run/docker.sock"
domain = "${TRAEFIK_DOMAIN}"
watch = true
exposedbydefault = false
