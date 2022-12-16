{{/*
A common pod spec across the different kubernetes types: deployment, daemonset, statefulset.
*/}}
{{- define "cray-etcd-base.common-spec" -}}
{{- $root := . -}}
{{- if .Values.hostname }}
hostname: "{{ .Values.hostname }}"
{{- end }}
{{- if .Values.serviceAccountName }}
serviceAccountName: "{{ .Values.serviceAccountName }}"
{{- else if .Values.etcd.enabled }}
serviceAccountName: "jobs-watcher"
{{- end }}
{{- if .Values.etcd.enabled }}
  {{- $input := dict "JobName" (nospace (cat (include "cray-etcd-base.fullname" $root) "-wait-for-etcd")) "Root" $root }}
  {{- include "cray-etcd-base.common-wait-for-job-container" $input }}
{{- end }}
{{- end }}
