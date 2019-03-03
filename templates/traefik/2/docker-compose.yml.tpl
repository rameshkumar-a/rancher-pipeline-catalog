version: '2'
services:
  traefik:
    labels:
      io.rancher.scheduler.global: 'true'
      io.rancher.scheduler.affinity:host_label: ${host_label}
      io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    {{- if eq .Values.rancher_integration "api"}}
      io.rancher.container.agent.role: environment
      io.rancher.container.create_agent: 'true'
    {{- end}}
      io.rancher.container.hostname_override: container_name
    image: rawmind/alpine-traefik:1.6.5-0
    environment:    
    - TRAEFIK_HTTPS_ENABLE=true
    - TRAEFIK_USAGE_ENABLE=${usage_enable}
    - TRAEFIK_ADMIN_ENABLE=true
    - TRAEFIK_ADMIN_PORT=8000
    - TRAEFIK_ADMIN_STATISTICS=${admin_statistics}
    - TRAEFIK_ADMIN_AUTH_METHOD=${admin_auth_method}
    - TRAEFIK_ADMIN_AUTH_USERS=${admin_users}
  {{- if ne .Values.rancher_integration "external"}}
    - TRAEFIK_RANCHER_ENABLE=true
    - TRAEFIK_FILE_ENABLE=false
    - TRAEFIK_CONSTRAINTS=${constraints}
    - TRAEFIK_RANCHER_HEALTHCHECK=${rancher_healthcheck}
    - TRAEFIK_RANCHER_MODE=${rancher_integration}
  {{- else}}
    - TRAEFIK_FILE_ENABLE=true
  {{- end}}
  {{- if eq .Values.metrics_enable "true"}}
    - TRAEFIK_METRICS_ENABLE=${metrics_enable}
    - TRAEFIK_METRICS_EXPORTER=${metrics_exporter}
    - TRAEFIK_METRICS_PUSH=${metrics_push}
    - TRAEFIK_METRICS_ADDRESS=${metrics_address}
    - TRAEFIK_METRICS_PROMETHEUS_BUCKETS=${metrics_prometheus_buckets}
  {{- end}}
  {{- if eq .Values.rancher_integration "external"}}
  traefik-conf:
    labels:
      io.rancher.scheduler.global: 'true'
      io.rancher.scheduler.affinity:host_label: ${host_label}
      io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.start_once: 'true'
    image: rawmind/rancher-traefik:1.5.0-0
    network_mode: none
    volumes:
      - tools-volume:/opt/tools
  {{- end}}
  {{- if (.Values.TRAEFIK_LB_PUBLISH_PORT)}}
  traefik-lb:
    image: rancher/lb-service-haproxy:v0.9.3
    ports:
      - ${TRAEFIK_LB_PUBLISH_PORT}:${TRAEFIK_LB_PUBLISH_PORT}
  {{- end}}
