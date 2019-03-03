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
    - 'mkdir -p /etc/sensu/conf.d/ && wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/influxdb/influx.json && wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/mattermost/handler-mattermost.json  &&  wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/util/replace_script.sh && chmod +x /etc/sensu/conf.d/replace_script.sh  && /etc/sensu/conf.d/replace_script.sh MATTERMOST_URL ${MATTERMOST_URL} /etc/sensu/conf.d/handler-mattermost.json && /etc/sensu/conf.d/replace_script.sh MATTERMOST_USER_NAME ${MATTERMOST_USER_NAME} /etc/sensu/conf.d/handler-mattermost.json && /etc/sensu/conf.d/replace_script.sh influxdb_password ${influxdb_db_pass} /etc/sensu/conf.d/influx.json && wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/influxdb/handlers.json && wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/check/check_cpu_metrics.json && wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/check/check_cpu_percentage.json && wget -P /etc/sensu/conf.d/  https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/check/check_https_status.json && /etc/sensu/conf.d/replace_script.sh HOST_URL ${HOST_URL} /etc/sensu/conf.d/check_https_status.json && 	/etc/sensu/conf.d/replace_script.sh CHECK_NAME ${CHECK_NAME} /etc/sensu/conf.d/check_https_status.json'
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
    - 'mkdir -p /etc/sensu/conf.d/ && wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/influxdb/influx.json && wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/mattermost/handler-mattermost.json  &&  wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/util/replace_script.sh && chmod +x /etc/sensu/conf.d/replace_script.sh  && /etc/sensu/conf.d/replace_script.sh MATTERMOST_URL ${MATTERMOST_URL} /etc/sensu/conf.d/handler-mattermost.json && /etc/sensu/conf.d/replace_script.sh MATTERMOST_USER_NAME ${MATTERMOST_USER_NAME} /etc/sensu/conf.d/handler-mattermost.json && /etc/sensu/conf.d/replace_script.sh influxdb_password ${influxdb_db_pass} /etc/sensu/conf.d/influx.json && wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/influxdb/handlers.json && wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/check/check_cpu_metrics.json && wget -P /etc/sensu/conf.d/ https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/check/check_cpu_percentage.json && wget -P /etc/sensu/conf.d/  https://raw.githubusercontent.com/rameshkumar-a/sensu_1_4_config/master/check/check_https_status.json && /etc/sensu/conf.d/replace_script.sh HOST_URL ${HOST_URL} /etc/sensu/conf.d/check_https_status.json && 	/etc/sensu/conf.d/replace_script.sh CHECK_NAME ${CHECK_NAME} /etc/sensu/conf.d/check_https_status.json'
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
      SENSU_DC_NAME: ${DATA_CENTER_NAME}
      SENSU_HOSTNAME: api
     {{- if eq .Values.use_dns_name_check "true" }}	  
    labels:  
      traefik.enable: true
      traefik.domain: ${domain_to_register_dns}
      traefik.port: 3000 
      traefik.alias.fqdn: ${uchiwa_dns_name_value}
      traefik.frontend.rule: Host:${uchiwa_dns_name_value}
    {{- else}}
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
      INFLUXDB_ADMIN_PASSWORD: ${influxdb_admin_pass}
      INFLUXDB_DB: metrics
      INFLUXDB_USER: metrics
      INFLUXDB_USER_PASSWORD: ${influxdb_db_pass}  
     {{- if eq .Values.use_dns_name_check "true" }}	  
    labels:
      traefik.enable: true
      traefik.domain: ${domain_to_register_dns}
      traefik.port: 8086
      traefik.alias.fqdn: ${influxdb_dns_name_value}
      traefik.frontend.rule: Host:${influxdb_dns_name_value}
    {{- end}}
  grafana:
    restart: always
    image: grafana/grafana    
    links:
      - influxdb:influxdb
    stdin_open: true
    labels:
      io.rancher.sidekicks: grafana-datasource,grafana-dashboards-config,grafana-dashboards-data
   {{- if eq .Values.use_dns_name_check "true" }}
      traefik.enable: true
      traefik.domain: ${domain_to_register_dns}
      traefik.port: 3000
      traefik.alias.fqdn: ${grafana_dns_name_value}
      traefik.frontend.rule: Host:${grafana_dns_name_value}
   	{{- else}}
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
    - 'mkdir -p /etc/grafana/provisioning/datasources/ && wget -P /etc/grafana/provisioning/datasources/ ${grafana_datasource_path} && wget -P /etc/grafana/provisioning/datasources/  https://raw.githubusercontent.com/rameshkumar-a/grafana-data/master/datasource/text_replacescript.sh && chmod +x /etc/grafana/provisioning/datasources/text_replacescript.sh && /etc/grafana/provisioning/datasources/text_replacescript.sh ${influxdb_db_pass}'
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