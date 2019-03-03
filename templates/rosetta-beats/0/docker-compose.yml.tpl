version: '2'
volumes:
  filebeat-config:
    driver: ${volumedriver}
  dockbeat-config:
    driver: ${volumedriver}

services:
  filebeat:
    image: docker.elastic.co/beats/filebeat:6.5.0
    hostname: filebeat
    restart: always
    volumes_from:
    - filebeat-config
    command: filebeat -c filebeat.yml --modules system
    labels:
      io.rancher.sidekicks: filebeat-config

  filebeat-config:
    image: ekannku/rosetta-filebeat:1.0.0
    entrypoint: /bin/sh
    volumes:
    - filebeat-config:/usr/share/filebeat
    labels:
      io.rancher.container.start_once: true
    command:
    - -c
    - 'wget ${gitlab_config_path}/raw/master/filebeat/filebeat.yml -O /usr/share/filebeat/filebeat.yml && sed -ie "s:REPLACE:${domain_name}\:5044:g"  /usr/share/filebeat/filebeat.yml && rm -f /usr/share/filebeat/filebeat.ymle && wget ${gitlab_config_path}/raw/master/filebeat/default.yml -O /usr/share/filebeat/prospectors.d/default.yml'


  dockbeat:
    image: ingensi/dockbeat
    stdin_open: true
    tty: true
    privileged: true
    restart: always
    hostname: dockbeat
    volumes_from:
    - dockbeat-config
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    labels:
      io.rancher.sidekicks: dockbeat-config

  dockbeat-config:
    image: busybox
    stdin_open: true
    tty: true
    entrypoint: /bin/sh
    volumes:
    - dockbeat-config:/etc/dockbeat
    command:
    - -c
    - 'wget ${gitlab_config_path}/raw/master/dockbeat/dockbeat.yml -O /etc/dockbeat/dockbeat.yml && sed -ie "s:REPLACE:${domain_name}\:5045:g"  /etc/dockbeat/dockbeat.yml'
    labels:
      io.rancher.container.start_once: true
    depends_on:
    - filebeat
