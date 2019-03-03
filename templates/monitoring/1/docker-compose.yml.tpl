version: '2'
volumes:
  influxdb-data:
    driver: ${volumedriver}
  redis-data:
    driver: ${volumedriver}
  sensu-config-api-data:
    driver: ${volumedriver}
  sensu-config-server-data:
    driver: ${volumedriver}
  grafana-datasource-data:
    driver: ${volumedriver}
  sensu-backend-lib:
    driver: ${volumedriver}
  grafana-dashboards-data:
    driver: ${volumedriver}
  sensu-influx-handler-bin:
    driver: ${volumedriver}
services:
  redis:
    restart: always
    image: redis:3
    container_name: redis
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
  sensu-config-api:
    labels:
        io.rancher.container.start_once: true
    tty: true
    image: busybox
    entrypoint: /bin/sh
    command:
    - -c
    - 'mkdir -p /etc/sensu/conf.d/ && wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/influxdb/influx.json && wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/mattermost/handler-mattermost.json  &&  wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/util/replace_script.sh && chmod +x /etc/sensu/conf.d/replace_script.sh  && /etc/sensu/conf.d/replace_script.sh mattermost_url ${mattermost_url} /etc/sensu/conf.d/handler-mattermost.json && /etc/sensu/conf.d/replace_script.sh mattermost_username ${mattermost_username} /etc/sensu/conf.d/handler-mattermost.json && /etc/sensu/conf.d/replace_script.sh influxdb_password ${influxdb_db_password} /etc/sensu/conf.d/influx.json && wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/influxdb/handlers.json && wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/check/check_cpu_metrics.json && wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/check/check_cpu_percentage.json && wget -P /etc/sensu/conf.d/  ${configuration_repo_path}/raw/master/check/check_https_status.json && /etc/sensu/conf.d/replace_script.sh default_check_url ${default_check_url} /etc/sensu/conf.d/check_https_status.json && 	/etc/sensu/conf.d/replace_script.sh default_check_name ${default_check_name} /etc/sensu/conf.d/check_https_status.json'
    container_name: sensu-config-api
    volumes:
      - sensu-config-api-data:/etc/sensu/conf.d/
  sensu-config-server:
    labels:
        io.rancher.container.start_once: true
    tty: true
    image: busybox
    entrypoint: /bin/sh
    command:
    - -c
    - 'mkdir -p /etc/sensu/conf.d/ && wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/influxdb/influx.json && wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/mattermost/handler-mattermost.json  &&  wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/util/replace_script.sh && chmod +x /etc/sensu/conf.d/replace_script.sh  && /etc/sensu/conf.d/replace_script.sh mattermost_url ${mattermost_url} /etc/sensu/conf.d/handler-mattermost.json && /etc/sensu/conf.d/replace_script.sh mattermost_username ${mattermost_username} /etc/sensu/conf.d/handler-mattermost.json && /etc/sensu/conf.d/replace_script.sh influxdb_password ${influxdb_db_password} /etc/sensu/conf.d/influx.json && wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/influxdb/handlers.json && wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/check/check_cpu_metrics.json && wget -P /etc/sensu/conf.d/ ${configuration_repo_path}/raw/master/check/check_cpu_percentage.json && wget -P /etc/sensu/conf.d/  ${configuration_repo_path}/raw/master/check/check_https_status.json && /etc/sensu/conf.d/replace_script.sh default_check_url ${default_check_url} /etc/sensu/conf.d/check_https_status.json && 	/etc/sensu/conf.d/replace_script.sh default_check_name ${default_check_name} /etc/sensu/conf.d/check_https_status.json'
    container_name: sensu-config-server
    volumes:
      - sensu-config-server-data:/etc/sensu/conf.d/
  api:
    restart: always
    image: rameshkumara/sensu-server:0.16
    command: api
    container_name: api
    stdin_open: true
    links:
      - redis:redis
    labels:
      io.rancher.sidekicks: sensu-config-api
    volumes_from:
      - sensu-config-api
  server:
    restart: always
    image: rameshkumara/sensu-server:0.16
    command: server
    container_name: server
    stdin_open: true
    links:
      - redis:redis
      - api:api
    labels:
      io.rancher.sidekicks: sensu-config-server
    volumes_from:
      - sensu-config-server
  uchiwa:
    restart: always
    image: sstarcher/uchiwa
    container_name: uchiwa
    stdin_open: true
    links:
      - api:api
    environment:
      SENSU_DC_NAME: ${datacenter_name}
      SENSU_HOSTNAME: api
    labels:
      traefik.enable: true
      traefik.domain: ${service_tld}
      traefik.port: 3000
      traefik.alias.fqdn: ${uchiwa_subdomain}.${service_tld}
    ports:
      - '3000:3000'
    {{- end}}
  influxdb:
    restart: always
    image: influxdb
    stdin_open: true
    volumes:
      - influxdb-data:/var/lib/influxdb
    environment:
      INFLUXDB_ADMIN_ENABLED: true
      INFLUXDB_ADMIN_USER: admin
      INFLUXDB_ADMIN_PASSWORD: ${influxdb_admin_password}
      INFLUXDB_DB: metrics
      INFLUXDB_USER: metrics
      INFLUXDB_USER_PASSWORD: ${influxdb_db_password}
    labels:
      traefik.enable: true
      traefik.domain: ${service_tld}
      traefik.port: 8086
      traefik.alias.fqdn: ${influxdb_subdomain}.${service_tld}
  grafana:
    restart: always
    image: grafana/grafana
    links:
      - influxdb:influxdb
    stdin_open: true
    labels:
      io.rancher.sidekicks: grafana-datasource,grafana-dashboards-config,grafana-dashboards-data
      traefik.enable: true
      traefik.domain: ${service_tld}
      traefik.port: 3000
      traefik.alias.fqdn: ${grafana_subdomain}.${service_tld}
    ports:
      - '3001:3000'
    {{- end}}
    volumes_from:
      - grafana-datasource
      - grafana-dashboards-config
      - grafana-dashboards-data
    environment:
      - GF_INSTALL_PLUGINS=grafana-clock-panel,briangann-gauge-panel,natel-plotly-panel,grafana-simple-json-datasource
  grafana-datasource:
    labels:
        io.rancher.container.start_once: true
    tty: true
    image: busybox
    entrypoint: /bin/sh
    command:
    - -c
    - 'mkdir -p /etc/grafana/provisioning/datasources/ && wget -P /etc/grafana/provisioning/datasources/ ${grafana_datasource_path} && wget -P /etc/grafana/provisioning/datasources/  ${configuration_repo_path}/raw/master/datasource/text_replacescript.sh && chmod +x /etc/grafana/provisioning/datasources/text_replacescript.sh && /etc/grafana/provisioning/datasources/text_replacescript.sh ${influxdb_db_password}'
    container_name: grafana-datasource
    volumes:
      - grafana-datasource-data:/etc/grafana/provisioning/datasources
  grafana-dashboards-config:
    labels:
        io.rancher.container.start_once: true
    tty: true
    image: busybox
    command: wget -P /etc/grafana/provisioning/dashboards/ ${grafana_dashboard_path}
    container_name: grafana-dashboards-config
    volumes:
      - grafana-dashboards-config:/etc/grafana/provisioning/dashboards
  grafana-dashboards-data:
    labels:
        io.rancher.container.start_once: true
    tty: true
    image: busybox
    command: wget -P /var/lib/grafana/dashboards ${grafana_dashboard_json}
    container_name: grafana-dashboards-data
    volumes:
      - grafana-dashboards-data:/var/lib/grafana/dashboards
