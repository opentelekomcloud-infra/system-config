{{/*
Common labels for the opensearch additional-manifests chart.
*/}}
{{- define "opensearch-additional.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opensearch-additional.labels" -}}
helm.sh/chart: {{ include "opensearch-additional.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: opensearch
{{- end }}
