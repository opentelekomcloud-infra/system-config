---
# Nodepool openstacksdk configuration
#
# This file is deployed to nodepool launcher and builder hosts
# and is used there to authenticate nodepool operations to clouds.
# This file only contains projects we are launching test nodes in, and
# the naming should correspond that used in nodepool configuration
# files.
#
# Generated automatically, please do not edit directly!
cache:
  expiration:
    server: 5
    port: 5
    floating-ip: 5
clouds:
  otcci-pool1:
    auth:
{{- with secret "secret/clouds/otcci_nodepool_pool1" }}
{{- with secret (printf "secret/%s" .Data.data.user_secret_name) }}
       auth_url: "{{ .Data.data.auth_url }}"
       user_domain_name: "{{ .Data.data.user_domain_name }}"
       username: "{{ .Data.data.username }}"
       password: "{{ .Data.data.password }}"
{{- end }}
       project_name: "{{ .Data.data.project_name }}"
{{- end }}
    private: true
    disable_volume_api: true
  otcci-pool2:
    auth:
{{- with secret "secret/clouds/otcci_nodepool_pool2" }}
{{- with secret (printf "secret/%s" .Data.data.user_secret_name) }}
       auth_url: "{{ .Data.data.auth_url }}"
       user_domain_name: "{{ .Data.data.user_domain_name }}"
       username: "{{ .Data.data.username }}"
       password: "{{ .Data.data.password }}"
{{- end }}
       project_name: "{{ .Data.data.project_name }}"
{{- end }}
    private: true
    disable_volume_api: true
  otcci-pool3:
    auth:
{{- with secret "secret/clouds/otcci_nodepool_pool3" }}
{{- with secret (printf "secret/%s" .Data.data.user_secret_name) }}
       auth_url: "{{ .Data.data.auth_url }}"
       user_domain_name: "{{ .Data.data.user_domain_name }}"
       username: "{{ .Data.data.username }}"
       password: "{{ .Data.data.password }}"
{{- end }}
       project_name: "{{ .Data.data.project_name }}"
{{- end }}
    private: true
    disable_volume_api: true
