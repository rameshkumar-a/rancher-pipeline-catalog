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
      bash -c "for ((i=1; i<=30; i=i+1)); do http_response=`curl ${gitlab_external_url_prefix}"${gitlab_subdomain}.${service_tld}"/users/sign_in -s -o /dev/null -I -w \"%{http_code}\"`; echo $${http_response}; if [ $${http_response} -eq 200 ]; then gitlab_host=\"${gitlab_external_url_prefix}"${gitlab_subdomain}.${service_tld}"\"; gitlab_user=\"root\"; gitlab_password=\""${gitlab_root_password}"\"; body_header=$$(curl -c cookies.txt -i "$${gitlab_host}/users/sign_in" -s); echo $${body_header}; csrf_token=$$(echo $$body_header | perl -ne 'print \"$$1\\n\" if /new_user.*?authenticity_token\"[[:blank:]]value=\"(.+?)\"/' | sed -n 1p); echo $${csrf_token}; curl -b cookies.txt -c cookies.txt -i \"$${gitlab_host}/users/sign_in\" --data \"user[login]=$${gitlab_user}&user[password]=$${gitlab_password}\" --data-urlencode \"authenticity_token=$${csrf_token}\"; body_header=$$(curl -H 'user-agent: curl' -b cookies.txt -i \"$${gitlab_host}/profile/personal_access_tokens\" -s); echo $${body_header}; csrf_token=$$(echo $$body_header | perl -ne 'print \"$$1\\n\" if /authenticity_token\"[[:blank:]]value=\"(.+?)\"/' | sed -n 1p); body_header=$$(curl -L -b cookies.txt \"$${gitlab_host}/profile/personal_access_tokens\" --data-urlencode \"authenticity_token=$${csrf_token}\" --data 'personal_access_token[name]=golab-generated&personal_access_token[expires_at]=&personal_access_token[scopes][]=api'); echo $${csrf_token}; personal_access_token=$$(echo $$body_header | perl -ne 'print \"$$1\\n\" if /created-personal-access-token\"[[:blank:]]value=\"(.+?)\"/' | sed -n 1p); echo $${personal_access_token}; curl --request PUT --header \"PRIVATE-TOKEN: $${personal_access_token}\" '${gitlab_external_url_prefix}"${gitlab_subdomain}"/api/v4/application/settings?plantuml_enabled=true&&plantuml_url="${plantuml_url_prefix}${plantuml_subdomain}.${service_tld}"'; break; fi; sleep 60; done"
    labels:
      io.rancher.container.start_once: 'true'
    depends_on:
      - gitlab-server
  plantuml:
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
      - ${gitlab_ssh_port}:22
    hostname: ${gitlab_subdomain}.${service_tld}
    restart: always
    stdin_open: true
    tty: true
    image: gitlab/gitlab-ee:11.6.0-ee.0
    privileged: true
{{- if eq .Values.plantuml_enabled "true" }}
    links:
      - plantuml:plantuml
{{- end }}
    volumes:
      - gitlab-conf-files:/etc/gitlab
      - gitlab-log-data:/var/log/gitlab
      - gitlab-app-data:/var/opt/gitlab
    labels:
     - "traefik.enable=stack"
     - "traefik.domain=${service_tld}"
     - "traefik.port=80"
     - "traefik.alias.fqdn=${gitlab_subdomain}.${service_tld}"
     - "gitlab"
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url '${gitlab_external_url_prefix}${gitlab_subdomain}.${service_tld}'
        gitlab_rails['lfs_enabled'] = true
        gitlab_rails['gitlab_shell_ssh_port'] = ${gitlab_ssh_port}
        gitlab_rails['gitlab_ssh_host'] ='${gitlab_ssh_host}'
        gitlab_rails['gitlab_email_enabled'] = true
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
        gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
        nginx['client_max_body_size'] = '${client_max_body_size}'
        nginx['listen_port'] = '${nginx_listen_port}'
        nginx['listen_https'] = ${nginx_listen_https}
        nginx['redirect_http_to_https'] = ${nginx_redirect_http_to_https}
        letsencrypt['enable'] = false
{{- if eq .Values.azure_auth_enabled "true" }}
        gitlab_rails['omniauth_enabled'] = true
        gitlab_rails['omniauth_allow_single_sign_on'] = ['azure_oauth2']
        gitlab_rails['omniauth_sync_profile_from_provider'] = ['azure_oauth2']
        gitlab_rails['omniauth_sync_profile_attributes'] = ['name','email']
        gitlab_rails['omniauth_block_auto_created_users'] = false
        gitlab_rails['omniauth_auto_link_ldap_user'] = true
        gitlab_rails['omniauth_providers'] = [{"name" => "azure_oauth2", "args" => {"client_id" => "${azure_auth_client_id}", "client_secret" => "${azure_auth_client_secret}", "tenant_id" => "${azure_auth_tenant_id}"}}]
{{- end }}
{{- if (eq .Values.pages_enabled "true") }}
        pages_external_url "${pages_url_prefix}${pages_subdomain}.${service_tld}"
        pages_nginx['enable'] = false
        pages_nginx['listen_port'] = '80'
        pages_nginx['listen_https'] = false
        pages_nginx['redirect_http_to_https'] = false
        gitlab_pages['external_http'] = ':${pages_port}'
{{- end }}
{{- if eq .Values.mattermost_enabled "true"}}
        mattermost_external_url '${mattermost_url_prefix}${mattermost_subdomain}.${service_tld}'
        mattermost['team_site_name'] = "${mattermost_team_site_name}"
        mattermost_nginx['listen_port'] = '80'
        mattermost_nginx['listen_https'] = false
        mattermost_nginx['redirect_http_to_https'] = false
        mattermost['gitlab_token_endpoint'] = "${gitlab_external_url_prefix}${internal_gitlab_subdomain}.${service_tld}/oauth/token"
        mattermost['gitlab_user_api_endpoint'] = "${gitlab_external_url_prefix}${internal_gitlab_subdomain}.${service_tld}/api/v4/user"
{{- end}}
{{- if eq .Values.plantuml_enabled "true" }}
      GITLAB_ROOT_PASSWORD: "${gitlab_root_password}"
{{- end }}
