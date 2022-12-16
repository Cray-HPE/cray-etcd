{{/*
A common set of labels to apply to resources.
*/}}
{{- define "cray-etcd-base.common-labels" -}}
helm.sh/base-chart: {{ include "cray-etcd-base.base-chart" . }}
helm.sh/chart: {{ include "cray-etcd-base.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{ with .Values.labels -}}
{{ toYaml . -}}
{{- end -}}
{{- end -}}
