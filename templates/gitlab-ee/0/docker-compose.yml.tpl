version: '2'
volumes:
  gitlab-app-data:
    driver: ${volumedriver}
  gitlab-log-data:
    driver: ${volumedriver}
  gitlab-conf-files:
    driver: ${volumedriver}

services:
  gitlab-server:
    ports:
      - ${ssh_port}:22/tcp
      - ${http_port}:80/tcp
      - ${https_port}:443/tcp
    labels:
      io.rancher.container.hostname_override: container_name
    image: gitlab/gitlab-ee:10.2.8-ee.0
    volumes:
      - gitlab-app-data:/var/opt/gitlab
      - gitlab-log-data:/var/log/gitlab
      - gitlab-conf-files:/etc/gitlab
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url '${gitlab_omnibus_prefix}${gitlab_hostname}'
        registry_external_url '${gitlab_omnibus_prefix}${registry_gitlab_hostname}'
        gitlab_rails['gitlab_shell_ssh_port'] = ${ssh_port}