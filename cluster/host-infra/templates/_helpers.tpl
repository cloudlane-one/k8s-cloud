{{/*
Generate hostname from domain and subdomain.

Params:
  - service - String - Required - Name of the service to generate a hostname for.
  - context - Context - Required - Parent context.

Usage:
{{ include "get_hostname" (dict "service" "my-service" "context" $) }}

*/}}
{{- define "get_hostname" -}}
  {{ $subdomain := .service }}
  {{- if hasKey .context.Values.subdomains .service }}
    {{- $subdomain = index .context.Values.subdomains .service -}}
  {{- end -}}
  {{ printf "%s.%s" $subdomain .context.Values.domain }}
{{- end -}}

{{/*
Generate annotations for autheticating an nginx ingress via oauth2-proxy, 
making it available only to admins.

Usage:
{{ include "admin_auth_annotations" . }}

*/}}
{{- define "admin_auth_annotations" -}}
# As described in this docs section: https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview/#configuring-for-use-with-the-nginx-auth_request-directive
nginx.ingress.kubernetes.io/auth-response-headers: Authorization
nginx.ingress.kubernetes.io/auth-signin: {{ printf "https://%s/oauth2/start?rd=$scheme%%3A%%2F%%2F$host$escaped_request_uri" (include "get_hostname" (dict "service" "oauth2_proxy" "context" $)) }}
nginx.ingress.kubernetes.io/auth-url: {{ printf "https://%s/oauth2/auth" (include "get_hostname" (dict "service" "oauth2_proxy" "context" $)) }}
nginx.ingress.kubernetes.io/configuration-snippet: |
  auth_request_set $name_upstream_1 $upstream_cookie__oauth2_proxy;

  access_by_lua_block {
    if ngx.var.name_upstream_1 ~= "" then
      ngx.header["Set-Cookie"] = "_oauth2_proxy=" .. ngx.var.name_upstream_1 .. ngx.var.auth_cookie:match("(; .*)")
    end
  }
{{- end -}}

{{/*
Return fully qualified name for cluster.

Usage:
{{ include "cluster_fqn" . }}

*/}}
{{- define "cluster_fqn" -}}
{{ printf "%s/%s" .Values.domain .Values.clusterName }}
{{- end -}}