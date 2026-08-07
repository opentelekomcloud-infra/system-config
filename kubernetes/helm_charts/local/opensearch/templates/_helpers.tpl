{{- define "opensearch-additional.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opensearch-additional.labels" -}}
helm.sh/chart: {{ include "opensearch-additional.chart" . }}
app.kubernetes.io/name: opensearch
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
