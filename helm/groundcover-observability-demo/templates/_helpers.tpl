{{- define "gc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gc.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "gc.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "gc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "gc.serviceAccountName" -}}
{{ include "gc.fullname" . }}-sa
{{- end -}}

{{- define "gc.otlpEndpoint" -}}
{{- if .Values.global.otlp.endpoint }}{{ .Values.global.otlp.endpoint }}{{ else }}
{{- if eq .Values.global.otlp.mode "direct" -}}
http://groundcover-opentelemetry-collector:4317
{{- else -}}
http://otel-collector:4317
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "gc.javaAgentOpts" -}}
{{- if .Values.global.javaAgent.enabled -}}
-javaagent:/otel/opentelemetry-javaagent.jar
{{- else -}}
{{/* return empty string (no quotes) to avoid invalid JAVA_TOOL_OPTIONS */}}
{{- end -}}
{{- end -}}
