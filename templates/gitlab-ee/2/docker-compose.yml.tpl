version: '2'

volumes:
  gitlab-app-data:
    driver: ${volumedriver}
  gitlab-log-data:
    driver: ${volumedriver}
  gitlab-conf-files:
    driver: ${volumedriver}

services:
{{- if eq .Values.plantuml_enabled "true" }}
  gitlab-plantuml-config:
    image: plantuml/plantuml-server:tomcat
    command: >
      bash -c "for ((i=1; i<=30; i=i+1)); do http_response=`curl http://"${gitlab_hostname}"/users/sign_in -s -o /dev/null -I -w \"%{http_code}\"`; echo $${http_response}; if [ $${http_response} -eq 200 ]; then gitlab_host=\"http://"${gitlab_hostname}"\"; gitlab_user=\"root\"; gitlab_password=\""${gitlab_root_password}"\"; body_header=$$(curl -c cookies.txt -i "$${gitlab_host}/users/sign_in" -s); echo $${body_header}; csrf_token=$$(echo $$body_header | perl -ne 'print \"$$1\\n\" if /new_user.*?authenticity_token\"[[:blank:]]value=\"(.+?)\"/' | sed -n 1p); echo $${csrf_token}; curl -b cookies.txt -c cookies.txt -i \"$${gitlab_host}/users/sign_in\" --data \"user[login]=$${gitlab_user}&user[password]=$${gitlab_password}\" --data-urlencode \"authenticity_token=$${csrf_token}\"; body_header=$$(curl -H 'user-agent: curl' -b cookies.txt -i \"$${gitlab_host}/profile/personal_access_tokens\" -s); echo $${body_header}; csrf_token=$$(echo $$body_header | perl -ne 'print \"$$1\\n\" if /authenticity_token\"[[:blank:]]value=\"(.+?)\"/' | sed -n 1p); body_header=$$(curl -L -b cookies.txt \"$${gitlab_host}/profile/personal_access_tokens\" --data-urlencode \"authenticity_token=$${csrf_token}\" --data 'personal_access_token[name]=golab-generated&personal_access_token[expires_at]=&personal_access_token[scopes][]=api'); echo $${csrf_token}; personal_access_token=$$(echo $$body_header | perl -ne 'print \"$$1\\n\" if /created-personal-access-token\"[[:blank:]]value=\"(.+?)\"/' | sed -n 1p); echo $${personal_access_token}; curl --request PUT --header \"PRIVATE-TOKEN: $${personal_access_token}\" 'http://"${gitlab_hostname}"/api/v4/application/settings?plantuml_enabled=true&&plantuml_url=http://"${gitlab_hostname}":"${plantuml_port}"'; break; fi; sleep 60; done"
    labels:
      io.rancher.container.start_once: 'true'
    depends_on:
      - gitlab-server
  plantuml:
    ports:
      - ${plantuml_port}:8080
    hostname: plantuml
    image: plantuml/plantuml-server:tomcat
{{- end }}
  gitlab-server:
    scale: 1
    retain_ip: true
    health_check:
      port: 80
      interval: 30000
      unhealthy_threshold: 3
      strategy: recreate
      response_timeout: 3000
      healthy_threshold: 2
    ports:
      - ${https_port}:443
      - ${http_port}:80
      - ${ssh_port}:22
    hostname: ${gitlab_hostname}
    restart: always
    stdin_open: true
    tty: true
    image: gitlab/gitlab-ee:11.0.4-ee.0
    privileged: true
{{- if eq .Values.plantuml_enabled "true" }}
    links:
      - plantuml:plantuml
{{- end }}
    volumes:
      - gitlab-conf-files:/etc/gitlab
      - gitlab-log-data:/var/log/gitlab 
      - gitlab-app-data:/var/opt/gitlab
{{- if eq .Values.use_dns_name_check "true" }}
    labels:
     - "traefik.enable=true"
     - "traefik.domain=${domain_to_register_dns}"
     - "traefik.port=80"
     - "traefik.alias.fqdn=${dns_name_value}"
     - "gitlab"
{{- end }}
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url '${gitlab_omnibus_prefix}${gitlab_hostname}'
        gitlab_rails['lfs_enabled'] = true
        gitlab_rails['gitlab_shell_ssh_port'] = ${ssh_port}
{{- if eq .Values.gitlab_email_enabled "true" }}
        gitlab_rails['gitlab_email_enabled'] = ${gitlab_email_enabled}
        gitlab_rails['gitlab_email_from'] = '${email_from}'
        gitlab_rails['gitlab_email_display_name'] = '${email_display_name}'
        gitlab_rails['gitlab_email_reply_to'] = '${email_reply_to}'
        gitlab_rails['smtp_enable'] = ${smtp_enable}
        gitlab_rails['smtp_address'] = '${smtp_address}'
        gitlab_rails['smtp_port'] = ${smtp_port}
        gitlab_rails['smtp_user_name'] = '${smtp_user_name}'
        gitlab_rails['smtp_password'] = '${smtp_password}'
        gitlab_rails['smtp_authentication'] = ${smtp_authentication}
        gitlab_rails['smtp_enable_starttls_auto'] = ${enable_starttls_auto}
        gitlab_rails['smtp_tls'] = ${smtp_tls}
        nginx['client_max_body_size'] = '${client_max_body_size}'
        nginx['listen_port'] = '${nginx_listen_port}'
        nginx['listen_https'] = ${nginx_listen_https}
        nginx['redirect_http_to_https'] = ${nginx_redirect_http_to_https}
        letsencrypt['enable'] = ${encrypt}
{{- end }}
{{- if eq .Values.azure_auth_enabled "true" }}
        gitlab_rails['omniauth_enabled'] = true
        gitlab_rails['omniauth_allow_single_sign_on'] = ['azure_oauth2']
        gitlab_rails['omniauth_sync_profile_from_provider'] = ['azure_oauth2']
        gitlab_rails['omniauth_sync_profile_attributes'] = ['name','email']
        gitlab_rails['omniauth_block_auto_created_users'] = false 
        gitlab_rails['omniauth_auto_link_ldap_user'] = true
        gitlab_rails['omniauth_external_providers'] = ['azure_oauth2']
        gitlab_rails['omniauth_providers'] = [{"name" => "azure_oauth2", "args" => {"client_id" => "${azure_auth_client_id}", "client_secret" => "${azure_auth_client_secret}", "tenant_id" => "${azure_auth_tenant_id}"}}]
{{- end }}
{{- if eq .Values.plantuml_enabled "true" }}
      GITLAB_ROOT_PASSWORD: "${gitlab_root_password}"
{{- end }}