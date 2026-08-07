{{/*
Common labels for the grafana chart. Mirrors the labels the former ansible
role set so selectors and existing objects stay compatible.
*/}}
{{- define "grafana.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "grafana.commonLabels" -}}
helm.sh/chart: {{ include "grafana.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: grafana
{{- end }}
