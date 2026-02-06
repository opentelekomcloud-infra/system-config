{{/*
Expand the name of the chart.
*/}}
{{- define "vault-additional.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "vault-additional.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vault-additional.labels" -}}
helm.sh/chart: {{ include "vault-additional.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
