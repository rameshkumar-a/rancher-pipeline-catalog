# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#        ___         __  _ ____           __
#       /   |  _____/ /_(_) __/___ ______/ /_____  _______  __
#      / /| | / ___/ __/ / /_/ __ `/ ___/ __/ __ \/ ___/ / / /
#     / ___ |/ /  / /_/ / __/ /_/ / /__/ /_/ /_/ / /  / /_/ /
#    /_/  |_/_/   \__/_/_/  \__,_/\___/\__/\____/_/   \__, /
#                                                    /____/
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

version: '2'

volumes:
  postgresql-data:
    driver: ${volumedriver}
{{- if eq .Values.enable_artifactory_ha "true" }}
  artifactory-node1-data:
    driver: ${volumedriver}
  artifactory-node2-data:
    driver: ${volumedriver}
  artifactory-ha-data:
    driver: ${volumedriver}
  artifactory-backup-data:
    driver: ${volumedriver}
{{- else }}
  artifactory-standalone-data:
    driver: ${volumedriver}
{{- end }}

services:
  postgresql:
    restart: always
    image: docker.bintray.io/postgres:9.6.11
    environment:
       POSTGRES_DB: artifactory
     # The following must match the DB_USER and DB_PASSWORD values passed to Artifactory
       POSTGRES_USER: ${postgres_username}
       POSTGRES_PASSWORD: ${postgres_password}
    volumes:
     - postgresql-data:/var/lib/postgresql/data
    ulimits:
      nproc: 65535
      nofile:
        soft: 32000
        hard: 40000
{{- if eq .Values.enable_artifactory_ha "true" }}
  artifactory-node1:
    restart: always
    container_name: artifactory-node1
    image: docker.bintray.io/jfrog/artifactory-pro:6.8.2
    depends_on:
     - postgresql
    links:
     - postgresql
    environment:
       HA_IS_PRIMARY: true
       HA_MEMBERSHIP_PORT: 10017
       HA_DATA_DIR: /var/opt/jfrog/artifactory-ha
       HA_BACKUP_DIR: /var/opt/jfrog/artifactory-backup
       DB_TYPE: postgresql
       DB_USER: ${postgres_username}
       DB_PASSWORD: ${postgres_password}
    volumes:
     - artifactory-node1-data:/var/opt/jfrog/artifactory
     - artifactory-ha-data:/var/opt/jfrog/artifactory-ha
     - artifactory-backup-data:/var/opt/jfrog/artifactory-backup
    ulimits:
      nproc: 65535
      nofile:
        soft: 32000
        hard: 40000
    labels:
     - "traefik.enable=stack"
     - "traefik.domain=${service_tld}"
     - "traefik.port=8081"
     - "traefik.alias.fqdn=${artifactory_subdomain}.${service_tld}"
     - "artifactory"
  artifactory-node2:
    restart: always
    container_name: artifactory-node2
    image: docker.bintray.io/jfrog/artifactory-pro:6.8.2
    depends_on:
     - postgresql
     - artifactory-node1
    links:
     - postgresql
     - artifactory-node1
    environment:
       HA_IS_PRIMARY: false
       HA_MEMBERSHIP_PORT: 10017
       HA_DATA_DIR: /var/opt/jfrog/artifactory-ha
       HA_BACKUP_DIR: /var/opt/jfrog/artifactory-backup
       DB_TYPE: postgresql
       DB_USER: ${postgres_username}
       DB_PASSWORD: ${postgres_password}
    volumes:
     - artifactory-node2-data:/var/opt/jfrog/artifactory
     - artifactory-ha-data:/var/opt/jfrog/artifactory-ha
     - artifactory-backup-data:/var/opt/jfrog/artifactory-backup
    ulimits:
      nproc: 65535
      nofile:
        soft: 32000
        hard: 40000
{{- else }}
  artifactory:
    restart: always
    container_name: artifactory
    image: docker.bintray.io/jfrog/artifactory-pro:6.8.2
    depends_on:
     - postgresql
    links:
     - postgresql
    environment:
       DB_TYPE: postgresql
       DB_USER: ${postgres_username}
       DB_PASSWORD: ${postgres_password}
    volumes:
     - artifactory-standalone-data:/var/opt/jfrog/artifactory
    ulimits:
      nproc: 65535
      nofile:
        soft: 32000
        hard: 40000
    labels:
     - "traefik.enable=stack"
     - "traefik.domain=${service_tld}"
     - "traefik.port=8081"
     - "traefik.alias.fqdn=${artifactory_subdomain}.${service_tld}"
     - "artifactory"
{{- end }}
