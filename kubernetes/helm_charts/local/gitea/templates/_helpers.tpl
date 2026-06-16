{{/*
Expand the name of the chart.
*/}}
{{- define "gitea-additional-manifests.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gitea-additional-manifests.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gitea-additional-manifests.labels" -}}
helm.sh/chart: {{ include "gitea-additional-manifests.chart" . }}
app.kubernetes.io/name: gitea
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
