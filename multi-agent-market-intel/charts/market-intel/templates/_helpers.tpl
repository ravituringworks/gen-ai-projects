{{- define "mi.image" -}}
{{- printf "%s/%s/%s:%s" .Values.image.registry .Values.image.org . $ | nindent 0 -}}
{{- end -}}
