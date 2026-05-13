{{/*
Expand the name of the chart.
*/}}
{{- define "gitea-additional-manifests.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gitea-additional-manifests.labels" -}}
app.kubernetes.io/name: gitea
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
