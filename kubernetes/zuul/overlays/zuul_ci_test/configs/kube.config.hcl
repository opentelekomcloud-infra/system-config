apiVersion: v1
kind: Config
current-context: otcci
preferences: {}

clusters:
  - name: otcci
    cluster:
      server: "https://192.168.21.182:5443"
      insecure-skip-tls-verify: true

contexts:
  - name: otcci
    context:
      cluster: otcci
      user: otcci-admin

users:
  - name: otcci-admin
    user:
{{- with secret "secret/kubernetes/otcci_k8s" }}
      client-certificate-data: "{{ base64Encode .Data.data.client_crt }}"
      client-key-data: "{{ base64Encode .Data.data.client_key }}"
{{- end }}
