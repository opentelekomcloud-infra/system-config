[zookeeper]
hosts=zookeeper.zuul-ci-test.svc.cluster.local:2281
tls_cert=/tls/client/tls.crt
tls_key=/tls/client/tls.key
tls_ca=/tls/client/ca.crt
session_timeout=40

[scheduler]
#tenant_config=/etc/zuul-config/zuul/main.yaml
tenant_config_script=/etc/zuul-config/tools/render_config.py
state_dir=/var/lib/zuul
relative_priority=true
prometheus_port=9091

[web]
listen_address=0.0.0.0
port=9000
status_url=https://zuul-test.otc-service.com
root=https://zuul-test.otc-service.com
prometheus_port=9091

[fingergw]
port=9079
user=zuul

[keystore]
{{- with secret "secret/zuul/keystore_password" }}
password={{ .Data.data.password }}
{{- end }}

[merger]
git_dir=/var/lib/zuul/git
git_timeout=600
git_user_email=zuul@zuul.otc-service.com
git_user_name=OpenTelekomCloud Zuul
prometheus_port=9091

[executor]
manage_ansible=true
ansible_root=/var/lib/zuul/managed_ansible
private_key_file=/etc/zuul/sshkey
disk_limit_per_job=2000
max_starting_builds=5
trusted_ro_paths=/var/run/zuul/trusted-ro
variables=/var/run/zuul/vars/site-vars.yaml
prometheus_port=9091

[database]
{{- with secret "database/static-creds/zuul-static" }}
dburi=postgresql://{{ .Data.username }}:{{ .Data.password }}@192.168.21.196:5432/zuul?sslmode=require
{{- end }}

[connection "github"]
name=github
driver=github
{{- with secret "secret/zuul/connections/github" }}
webhook_token={{ .Data.data.webhook_token }}
app_id={{ .Data.data.app_id }}
{{- end }}
app_key=/etc/zuul/connections/github.key

[connection "gitlab"]
name=gitlab
driver=gitlab
canonical_hostname=gitlab
cloneurl=ssh://git@git-ssh.tsi-dev.otc-service.com
server=git.tsi-dev.otc-service.com
{{- with secret "secret/zuul/connections/gitlab" }}
api_token={{ .Data.data.api_token }}
webhook_token={{ .Data.data.webhook_token }}
{{- end }}
sshkey=/etc/zuul/connections/gitlab.key

[connection "opendev"]
name=opendev
driver=git
baseurl=https://opendev.org

[connection "gitea"]
name=gitea
driver=gitea
baseurl=https://gitea.eco.tsi-dev.otc-service.com
server=gitea.eco.tsi-dev.otc-service.com
cloneurl=ssh://git@gitea.eco.tsi-dev.otc-service.com:2222
{{- with secret "secret/zuul/connections/gitea" }}
api_token={{ .Data.data.api_token }}
webhook_secret={{ .Data.data.webhook_secret }}
{{- end }}
sshkey=/etc/zuul/connections/gitea.key

[connection "smtp"]
name=smtp
driver=smtp
server=otc-de-out.mms.t-systems-service.com
port=25
default_from=zuul@zuul.otc-service.com
default_to=DL-PBCOTCDELECOCERT@t-systems.com
{{- with secret "secret/smtp_gw" }}
user={{ .Data.data.username }}
password={{ .Data.data.password }}
{{- end }}
use_starttls=True

[auth "keycloak"]
default=True
driver=OpenIDConnect
realm=eco
issuer_id=https://keycloak.eco.tsi-dev.otc-service.com/realms/eco
client_id=zuul
