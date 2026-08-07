{{/*
Common labels for the alerta chart. Mirrors the labels the former ansible
role set (app.kubernetes.io/name=alerta, /instance=<instance>) so selectors
and existing objects stay compatible.
*/}}
{{- define "alerta.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "alerta.commonLabels" -}}
helm.sh/chart: {{ include "alerta.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: alerta
{{- end }}
