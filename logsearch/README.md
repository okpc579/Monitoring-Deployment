## <div id='16'/>1.	Logsearch 설치

PaaS-TA VM Log수집을 위해서는 logsearch가 설치되어야 한다. 

```
$ cd ~/workspace/paasta-5.0/deployment/paasta-deployment-monitoring/paasta-monitoring
```

### <div id='17'/>1.1.	logsearch-deployment.yml
logsearch-deployment.yml에는 ls-router, cluster-monitor, elasticsearch_data, elastic_master, kibana, mainternance 의 명세가 정의되어 있다. 

```
---
name: logsearch
update:
  canaries: 3
  canary_watch_time: 30000-1200000
  max_in_flight: 1
  serial: false
  update_watch_time: 5000-1200000
instance_groups:
- name: elasticsearch_master
  azs:
  - z5
  instances: 1
  persistent_disk_type: 10GB
  vm_type: medium
  stemcell: default
  update:
    max_in_flight: 1
    serial: true
  networks:
  - name: default
  jobs:
  - name: elasticsearch
    release: logsearch
    consumes:
      elasticsearch: {from: elasticsearch_master}
    provides:
      elasticsearch: {as: elasticsearch_master}
    properties:
      elasticsearch:
        node:
          allow_master: true
  - name: syslog_forwarder
    release: logsearch
    consumes:
      syslog_forwarder: {from: cluster_monitor}
    properties:
      syslog_forwarder:
        config:
        - file: /var/vcap/sys/log/elasticsearch/elasticsearch.stdout.log
          service: elasticsearch
        - file: /var/vcap/sys/log/elasticsearch/elasticsearch.stderr.log
          service: elasticsearch
        - file: /var/vcap/sys/log/cerebro/cerebro.stdout.log
          service: cerebro
        - file: /var/vcap/sys/log/cerebro/cerebro.stderr.log
          service: cerebro
  - name: route_registrar
    release: logsearch-for-cloudfoundry
    consumes:
      nats: {from: nats, deployment: paasta}
    properties:
      route_registrar:
        routes:
        - name: elasticsearch
          port: 9200
          registration_interval: 60s
          uris:
          - "elastic.((system_domain))"

- name: cluster_monitor
  azs:
  - z6
  instances: 1
  persistent_disk_type: 10GB
  vm_type: medium
  stemcell: default
  update:
    max_in_flight: 1
    serial: true
  networks:
  - name: default
  jobs:
  - name: elasticsearch
    release: logsearch
    consumes:
      elasticsearch: {from: elasticsearch_cluster_monitor}
    provides:
      elasticsearch: {as: elasticsearch_cluster_monitor}
    properties:
      elasticsearch:
        cluster_name: monitor
        node:
          allow_data: true
          allow_master: true
  - name: elasticsearch_config
    release: logsearch
    consumes:
      elasticsearch: {from: elasticsearch_cluster_monitor}
    properties:
      elasticsearch_config:
        templates:
        - shards-and-replicas: '{ "template" : "logstash-*", "order" : 100, "settings"
            : { "number_of_shards" : 1, "number_of_replicas" : 0 } }'
        - index-settings: /var/vcap/jobs/elasticsearch_config/index-templates/index-settings.json
        - index-mappings: /var/vcap/jobs/elasticsearch_config/index-templates/index-mappings.json
  - name: ingestor_syslog
    release: logsearch
    provides:
      syslog_forwarder: {as: cluster_monitor}
    properties:
      logstash_parser:
        filters:
        - monitor: /var/vcap/packages/logsearch-config/logstash-filters-monitor.conf
  - name: curator
    release: logsearch
    consumes:
      elasticsearch: {from: elasticsearch_cluster_monitor}
    properties:
      curator:
        purge_logs:
          retention_period: 7
  - name: kibana
    release: logsearch
    consumes:
      elasticsearch: {from: elasticsearch_cluster_monitor}
    properties:
      kibana:
        memory_limit: 30
        wait_for_templates: [shards-and-replicas]
- name: maintenance
  azs:
  - z5
  - z6
  instances: 1
  vm_type: medium 
  stemcell: default
  update:
    serial: true
  networks:
  - name: default
  jobs:
  - name: elasticsearch_config
    release: logsearch
    consumes:
      elasticsearch: {from: elasticsearch_master}
    properties:
      elasticsearch_config:
        index_prefix: logs-
        templates:
          - shards-and-replicas: /var/vcap/jobs/elasticsearch_config/index-templates/shards-and-replicas.json
          - index-settings: /var/vcap/jobs/elasticsearch_config/index-templates/index-settings.json
          - index-mappings: /var/vcap/jobs/elasticsearch_config/index-templates/index-mappings.json
          - index-mappings-lfc: /var/vcap/jobs/elasticsearch-config-lfc/index-mappings.json
          - index-mappings-app-lfc: /var/vcap/jobs/elasticsearch-config-lfc/index-mappings-app.json
          - index-mappings-platform-lfc: /var/vcap/jobs/elasticsearch-config-lfc/index-mappings-platform.json
  - name: curator
    release: logsearch
    consumes:
      elasticsearch: {from: elasticsearch_master}
  - name: elasticsearch-config-lfc
    release: logsearch-for-cloudfoundry
  - name: syslog_forwarder
    release: logsearch
    consumes:
      syslog_forwarder: {from: cluster_monitor}
    properties:
      syslog_forwarder:
        config:
        - file: /var/vcap/sys/log/curator/curator.log
          service: curator
- name: elasticsearch_data
  azs:
  - z5
  - z6
  instances: 2
  persistent_disk_type: 30GB
  vm_type: medium 
  stemcell: default
  update:
    max_in_flight: 1
    serial: true
  networks:
  - name: default
  jobs:
  - name: elasticsearch
    release: logsearch
    consumes:
      elasticsearch: {from: elasticsearch_master}
    properties:
      elasticsearch:
        node:
          allow_data: true
  - name: syslog_forwarder
    release: logsearch
    consumes:
      syslog_forwarder: {from: cluster_monitor}
    properties:
      syslog_forwarder:
        config:
        - file: /var/vcap/sys/log/elasticsearch/elasticsearch.stdout.log
          service: elasticsearch
        - file: /var/vcap/sys/log/elasticsearch/elasticsearch.stderr.log
          service: elasticsearch
        - file: /var/vcap/sys/log/cerebro/cerebro.stdout.log
          service: cerebro
        - file: /var/vcap/sys/log/cerebro/cerebro.stderr.log
          service: cerebro
- name: kibana
  azs:
  - z5
  instances: 1
  persistent_disk_type: 5GB
  vm_type: medium 
  stemcell: default
  networks:
  - name: default

  jobs:
  - name: elasticsearch
    release: logsearch
    consumes:
      elasticsearch: {from: elasticsearch_master}
  - name: redis
    release: logsearch-for-cloudfoundry
    provides:
      redis: {as: redis_link}
  - name: kibana
    release: logsearch
    provides:
      kibana: {as: kibana_link}
    consumes:
      elasticsearch: {from: elasticsearch_master}
    properties:
      kibana:
        health:
          timeout: 300
        env:
          - NODE_ENV: production
  - name: syslog_forwarder
    release: logsearch
    consumes:
      syslog_forwarder: {from: cluster_monitor}
    properties:
      syslog_forwarder:
        config:
        - file: /var/vcap/sys/log/elasticsearch/elasticsearch.stdout.log
          service: elasticsearch
        - file: /var/vcap/sys/log/elasticsearch/elasticsearch.stderr.log
          service: elasticsearch
        - file: /var/vcap/sys/log/cerebro/cerebro.stdout.log
          service: cerebro
        - file: /var/vcap/sys/log/cerebro/cerebro.stderr.log
          service: cerebro
- name: ingestor
  azs:
  - z4
  - z6
  instances: 2
  persistent_disk_type: 10GB
  vm_type: medium 
  stemcell: default
  networks:
  - name: default
  jobs:
  - name: elasticsearch
    release: logsearch
    consumes:
      elasticsearch: {from: elasticsearch_master}
  - name: parser-config-lfc
    release: logsearch-for-cloudfoundry
  - name: ingestor_syslog
    release: logsearch
    provides:
      ingestor: {as: ingestor_link}
    properties:
      logstash_parser:
        filters:
          - logsearch-for-cf: /var/vcap/packages/logsearch-config-logstash-filters/logstash-filters-default.conf
        elasticsearch:
          index: logs-%{[@metadata][index]}-%{+YYYY.MM.dd}
        deployment_dictionary:
          - /var/vcap/packages/logsearch-config/deployment_lookup.yml
          - /var/vcap/jobs/parser-config-lfc/config/deployment_lookup.yml
  - name: syslog_forwarder
    release: logsearch
    consumes:
      syslog_forwarder: {from: cluster_monitor}
    properties:
      syslog_forwarder:
        config:
        - file: /var/vcap/sys/log/elasticsearch/elasticsearch.stdout.log
          service: elasticsearch
        - file: /var/vcap/sys/log/elasticsearch/elasticsearch.stderr.log
          service: elasticsearch
        - file: /var/vcap/sys/log/ingestor_syslog/ingestor_syslog.stdout.log
          service: ingestor
        - file: /var/vcap/sys/log/ingestor_syslog/ingestor_syslog.stderr.log
          service: ingestor
- name: ls-router
  azs:
  - z4
  instances: 1
  vm_type: small
  stemcell: default
  networks:
  - name: default
    static_ips: 
    - ((router_ip)) 
  jobs:
  - name: haproxy
    release: logsearch
    consumes:
      elasticsearch: {from: elasticsearch_master}
      ingestor: {from: ingestor_link}
      kibana: {from: kibana_link}
      syslog_forwarder: {from: cluster_monitor}
    properties:
      inbound_port:
        https: 4443
  - name: route_registrar
    release: logsearch-for-cloudfoundry
    consumes:
      nats: {from: nats, deployment: paasta}
    properties:
      route_registrar:
        routes:
        - name: kibana
          port: 80
          registration_interval: 60s
          uris:
          - "logs.((system_domain))"

variables:
- name: kibana_oauth2_client_secret
  type: password
- name: firehose_client_secret
  type: password

releases:
- name: logsearch
  url: file:///home/((inception_os_user_name))/workspace/paasta-5.0/release/paasta-monitoring/logsearch-boshrelease-209.0.1.tgz
  version: "209.0.1"
- name: logsearch-for-cloudfoundry
  url: file:///home/((inception_os_user_name))/workspace/paasta-5.0/release/paasta-monitoring/logsearch-for-cloudfoundry-207.0.1.tgz
  version: "207.0.1"
stemcells:
- alias: default
  os: ubuntu-xenial
  version: "315.36"
```

### <div id='18'/>1.2. deploy-logsearch.sh

deploy.sh의 –v 의 inception_os_user_name, router_ip, system_domain 및 director_name을 시스템 상황에 맞게 설정한다.
system_domain은 PaaS-TA 설치시 설정했던 system_domain을 입력하면 된다.
router_ip는 ls-router가 설치된 azs에서 정의한 cider값의 적당한 IP를 지정한다.

```
bosh –e {director_name} -d logsearch deploy logsearch-deployment.yml \
  -v inception_os_user_name=ubuntu \  # home user명 (release file path와 연관성 있음. /home/ubuntu/paasta-5.0 이하 release 파일들의 경로 설정)
  -v router_ip=10.20.50.34 \   # 배포한 ls-router VM의 private ip
  -v system_domain={system_domain}  #PaaS-TA 설치시 설정한 System Domain
```

deploy.sh을 실행하여 logsearch를 설치 한다.

```
$ cd ~/workspace/paasta-5.0/deployment/paasta-deployment-monitoring/paasta-monitoring
$ sh deploy-logsearch.sh
```

logsearch가 설치 완료 되었음을 확인한다.
```
$ bosh –e {director_name} vms
```
![PaaSTa_logsearch_vms_5.0]
