{{/*
Expand the name of the chart.
*/}}
{{- define "graphite.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "graphite.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "graphite.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "graphite.labels" -}}
helm.sh/chart: {{ include "graphite.chart" . }}
{{ include "graphite.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
Instance is pinned to the fullname (not .Release.Name) so the label is stable
regardless of the Helm release name used by the deployer (e.g. ArgoCD sets the
release name to the Application name). This keeps the immutable StatefulSet
selector / volumeClaimTemplates labels matching the originally-deployed objects.
*/}}
{{- define "graphite.selectorLabels" -}}
app.kubernetes.io/name: {{ include "graphite.name" . }}
app.kubernetes.io/instance: {{ include "graphite.fullname" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "graphite.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "graphite.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
