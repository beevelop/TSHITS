# Rundeck

## SMTP setings
add the following settings to `rundeck/data/etc/rundeck-config.properties`:
```
grails.mail.host=smtp.example.com
grails.mail.port=25
grails.mail.username=noreply@example.com
grails.mail.password=Swordfish
```

## Adding a node

Add the node to the `resources.xml` file at `rundeck/data/var/projects/Foobar/etc`:

```xml
<node name="foo.example.com" 
    description="foo" tags="ovh" 
    osFamily="unix" osName="Linux"
    hostname="foo.example.com"  username="bee" 
    />
```

or via YAML append to `resources.yaml`:

```yaml
foo.example.com:
  nodename: foo.example.com
  hostname: foo.example.com
  osFamily: unix
  osArch: amd64
  osName: Linux
  username: bee
  tags: 'example'
```

and add Rundeck's ssh public key to the host's authorized_keys file:

## Troubleshooting
- Upgrading the Rundeck Version and restarting the service might not update the Rundeck version... Sounds weird, but you need to remove the running container (e.g. using `docker-compose rm -f`)  and recreating it via `./bee up`.

