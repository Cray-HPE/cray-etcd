{{/*
A common set of annotations to apply to resources.
*/}}
{{- define "cray-etcd-base.common-annotations" -}}
cray.io/service: {{ include "cray-etcd-base.name" . }}
{{ with .Values.annotations -}}
{{ toYaml . -}}
{{- end -}}
{{- end -}}
