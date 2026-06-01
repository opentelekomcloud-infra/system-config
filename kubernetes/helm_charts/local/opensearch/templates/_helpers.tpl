{{- define "opensearch-additional.labels" -}}
app.kubernetes.io/name: opensearch
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
