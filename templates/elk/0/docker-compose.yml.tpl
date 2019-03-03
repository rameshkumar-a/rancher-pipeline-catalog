version: '2'
volumes:
  elastic-data:
    driver: ${volumedriver}
  elastic-config:
    driver: ${volumedriver}
  logstash-config-1:
    driver: ${volumedriver}
  logstash-config-2:
    driver: ${volumedriver}
  kibana-config:
    driver: ${volumedriver}

services:
  logstash-1:
    image: docker.elastic.co/logstash/logstash-oss:6.5.0
    stdin_open: true
    tty: true
    environment:
      LS_JAVA_OPTS: -Xmx256m -Xms256m
    volumes:
    - logstash-config-1:/usr/share/logstash
    labels:
      io.rancher.sidekicks: logstash-config-1

  logstash-config-1:
    image: busybox
    stdin_open: true
    tty: true
    entrypoint: /bin/sh
    volumes_from:
    - logstash-1
    command:
    - -c
    - 'wget ${configuration_repo_path}/raw/master/logstash/logstash.yml -O /usr/share/logstash/config/logstash.yml && wget ${configuration_repo_path}/raw/master/logstash/logstash1.conf -O /usr/share/logstash/pipeline/logstash.conf'
    labels:
      io.rancher.container.start_once: true

  logstash-2:
    image: docker.elastic.co/logstash/logstash-oss:6.5.0
    stdin_open: true
    tty: true
    environment:
      LS_JAVA_OPTS: -Xmx256m -Xms256m
    volumes:
    - logstash-config-2:/usr/share/logstash
    labels:
      io.rancher.sidekicks: logstash-config-2

  logstash-config-2:
    image: busybox
    stdin_open: true
    tty: true
    entrypoint: /bin/sh
    volumes_from:
    - logstash-2
    command:
    - -c
    - 'wget ${configuration_repo_path}/raw/master/logstash/logstash.yml -O /usr/share/logstash/config/logstash.yml && wget ${configuration_repo_path}/raw/master/logstash/logstash2.conf -O /usr/share/logstash/pipeline/logstash.conf'
    labels:
      io.rancher.container.start_once: true

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch-oss:6.5.0
    environment:
      ES_JAVA_OPTS: -Xmx256m -Xms256m
    stdin_open: true
    tty: true
    volumes:
    - elastic-config:/usr/share/elasticsearch/config
    - elastic-data:/usr/share/elasticsearch/data
    labels:
      io.rancher.sidekicks: elastic-config

  elastic-config:
    image: busybox
    stdin_open: true
    tty: true
    entrypoint: /bin/sh
    volumes_from:
    - elasticsearch
    command:
    - -c
    - 'wget ${configuration_repo_path}/raw/master/elasticsearch/elasticsearch.yml -O /usr/share/elasticsearch/config/elasticsearch.yml'
    labels:
      io.rancher.container.start_once: true

  kibana:
    image: docker.elastic.co/kibana/kibana-oss:6.5.0
    stdin_open: true
    tty: true
    volumes:
    - kibana-config:/usr/share/kibana/config
    labels:
      io.rancher.sidekicks: kibana-config
      traefik.enable: stack
      traefik.domain: ${service_tld}
      traefik.port: 5601
      traefik.alias.fqdn: ${kibana_subdomain}.${service_tld}

  kibana-config:
    image: busybox
    stdin_open: true
    tty: true
    entrypoint: /bin/sh
    volumes_from:
    - kibana
    command:
    - -c
    - 'wget ${configuration_repo_path}/raw/master/kibana/kibana.yml -O /usr/share/kibana/config/kibana.yml'
    labels:
      io.rancher.container.start_once: true
