{{/*
Generate annotations for autheticating an nginx ingress via oauth2-proxy.

Usage:
{{ include "proxy_auth_annotations" . }}

*/}}
{{- define "proxy_auth_annotations" -}}
nginx.ingress.kubernetes.io/auth-response-headers: "Authorization, X-Auth-Request-User, X-Auth-Request-Groups, X-Auth-Request-Email, X-Auth-Request-Preferred-Username, X-Auth-Request-Access-Token"
nginx.ingress.kubernetes.io/auth-signin: {{ printf "%s?rd=$scheme%%3A%%2F%%2F$host$escaped_request_uri" .Values.proxyAuthURLs.signin }}
nginx.ingress.kubernetes.io/auth-url: {{ .Values.proxyAuthURLs.auth }}
{{- end -}}
