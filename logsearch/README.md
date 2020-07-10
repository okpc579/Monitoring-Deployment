## Table of Contents

1. [개요](#1)  
2. [Logsearch 설치]()  
  2.1. [Prerequisite](#2)  
  2.2. [설치 파일 다운로드](#3)  
  2.3. [Logsearch 설치](#4)  
  * [logsearch-deployment.yml](#5)  
  * [deploy-logsearch.sh](#6)  
  * [logsearch-vars.yml](#7)  
  


## <div id='1'/>1. 개요

본 문서(Logsearch 설치 가이드)는 PaaS-TA Monitoring을 설치하기 앞서 BOSH와 PaaS-TA의 VM Log 수집을 위하여 BOSH 2.0을 이용하여 Logsearch를 설치하는 방법을 기술하였다.

## <div id='2'/>2. Logsearch 설치
### <div id='3'/>2.1 Prerequisite

1. BOSH 설치가 되어있으며, BOSH Login이 되어 있어야 한다.
2. Stemcell 목록을 확인하여 서비스 설치에 필요한 Stemcell이 업로드 되어 있는 것을 확인한다.
3. cloud-config와 runtime-config가 업데이트 되어있는지 확인한다.


> stemcell 확인  
> $ bosh -e {director-name} stemcells

```
Using environment '10.0.1.6' as client 'admin'

Name                                     Version  OS             CPI  CID  
bosh-aws-xen-hvm-ubuntu-xenial-go_agent  315.36*  ubuntu-xenial  -    ami-0297ff649e8eea21b  

(*) Currently deployed

1 stemcells

Succeeded
```

> cloud-config 확인
> $ bosh -e {director-name} cloud-config

> runtime-config 확인
> $ bosh -e {director-name} runtime-config


3. 


### <div id='1013'/>2.2. 설치 파일 다운로드

- Logsearch를 설치하기 위한 deployment가 존재하지 않는다면 다운로드 받는다
```
$ cd ${HOME}/workspace/paasta-5.0/deployment
$ git clone https://github.com/PaaS-TA/Common-Deployment.git common
$ git clone https://github.com/PaaS-TA/PaaS-TA-Deployment.git paasta-deployment
```
- release, stemcell을 [PaaS-TA 다운로드](https://paas-ta.kr/download/package)에서 내려받아 정해진 경로에 복사한다.(선택) 
- PaaS-TA 사이트에서 [PaaS-TA Release] 파일을 다운로드해 ${HOME}/workspace/paasta-5.0/release 이하 디렉터리에 압축을 푼다.
- PaaS-TA 사이트에서 [PaaS-TA Stemcell] 파일을 다운로드해 ${HOME}/workspace/paasta-5.0/stemcell 이하 디렉터리에 압축을 푼다.



## <div id='3'/>2. Logsearch 설치

PaaS-TA VM Log수집을 위해서는 Logsearch가 설치되어야 한다. 

```
$ cd ${HOME}/workspace/paasta-5.0/deployment/monitoring-deployment/paasta-monitoring
```

### <div id='4'/>2.1.	logsearch-deployment.yml
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
  azs: ((elasticsearch_master_azs))
  instances: ((elasticsearch_master_instances))
  persistent_disk_type: ((elasticsearch_master_persistent_disk_type))
  vm_type: ((elasticsearch_master_vm_type))
  stemcell: default
  update:
    max_in_flight: 1
    serial: true
  networks:
  - name: ((elasticsearch_master_network))
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
  azs: ((cluster_monitor_azs))
  instances: ((cluster_monitor_instances))
  persistent_disk_type: ((cluster_monitor_persistent_disk_type))
  vm_type: ((cluster_monitor_vm_type))
  stemcell: default
  update:
    max_in_flight: 1
    serial: true
  networks:
  - name: ((cluster_monitor_network))
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
  azs: ((maintenance_azs))
  instances: ((maintenance_instances))
  vm_type: ((maintenance_vm_type)) 
  stemcell: default
  update:
    serial: true
  networks:
  - name: ((maintenance_network))
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
  azs: ((elasticsearch_data_azs))
  instances: ((elasticsearch_data_instances))
  persistent_disk_type: ((elasticsearch_data_persistent_disk_type))
  vm_type: ((elasticsearch_data_vm_type)) 
  stemcell: default
  update:
    max_in_flight: 1
    serial: true
  networks:
  - name: ((elasticsearch_data_network))
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
  azs: ((kibana_azs))
  instances: ((kibana_instances))
  persistent_disk_type: ((kibana_persistent_disk_type))
  vm_type: ((kibana_vm_type)) 
  stemcell: default
  networks:
  - name: ((kibana_network))
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
  azs: ((ingestor_azs))
  instances: ((ingestor_instances))
  persistent_disk_type: ((ingestor_persistent_disk_type))
  vm_type: ((ingestor_vm_type)) 
  stemcell: default
  networks:
  - name: ((ingestor_network))
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
  azs: ((ls_router_azs))
  instances: ((ls_router_instances))
  vm_type: ((ls_router_vm_type))
  stemcell: default
  networks:
  - name: ((ls_router_network))
    static_ips: 
    - ((syslog_address)) 
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
  url: https://bosh.io/d/github.com/cloudfoundry-community/logsearch-boshrelease?v=209.0.1
  version: "209.0.1"
  sha1: 038b039dc30d71a4c3ed4570035867797538edef
- name: logsearch-for-cloudfoundry
  url: https://bosh.io/d/github.com/cloudfoundry-community/logsearch-for-cloudfoundry?v=207.0.1
  version: "207.0.1"
  sha1: 599d238be5281f5a2ef903936b9ef868611baab1
stemcells:
- alias: default
  os: ((stemcell_os)) 
  version: ((stemcell_version)) 
```

### <div id='4'/>2.2. deploy-logsearch.sh

deploy.sh의 –v 의 inception_os_user_name, router_ip, system_domain 및 director_name을 시스템 상황에 맞게 설정한다.  
system_domain은 PaaS-TA 설치시 설정했던 system_domain을 입력하면 된다.  
router_ip는 ls-router가 설치된 azs에서 정의한 cider값의 적당한 IP를 지정한다.

```
bosh –e {director_name} -d logsearch deploy logsearch-deployment.yml \				
	-o use-compiled-releases-logsearch.yml \
	-l logsearch-vars.yml \
	-l ../../common/common_vars.yml
```

### <div id='5'/>2.3. logsearch-vars.yml

```
# SERVICE VARIABLE
inception_os_user_name: "ubuntu"		# Deployment Name

# STEMCELL
stemcell_os: "ubuntu-xenial"			# Stemcell OS
stemcell_version: "315.36"			# Stemcell Version

# ELASTICSEARCH-MASTER
elasticsearch_master_azs: ["z5"]		# Elasticsearch-Master 가용 존
elasticsearch_master_instances: 1		# Elasticsearch-Master 인스턴스 수
elasticsearch_master_vm_type: "medium"		# Elasticsearch-Master VM 종류
elasticsearch_master_network: "default"		# Elasticsearch-Master 네트워크
elasticsearch_master_persistent_disk_type: "10GB"	# Elasticsearch-Master 영구 Disk 종류

# CLUSTER-MONITOR
cluster_monitor_azs: ["z6"]			# Cluster-Monitor 가용 존
cluster_monitor_instances: 1			# Cluster-Monitor 인스턴스 수
cluster_monitor_vm_type: "medium"		# Cluster-Monitor VM 종류
cluster_monitor_network: "default"		# Cluster-Monitor 네트워크
cluster_monitor_persistent_disk_type: "10GB"	# Cluster-Monitor 영구 Disk 종류

# MAINTENANCE
maintenance_azs: ["z5", "z6"]			# Maintenance 가용 존
maintenance_instances: 1			# Maintenance 인스턴스 수
maintenance_vm_type: "medium"			# Maintenance VM 종류
maintenance_network: "default"			# Maintenance 네트워크

# ELASTICSEARCH-DATA
elasticsearch_data_azs: ["z5", "z6"]		# Elasticsearch-Data 가용 존
elasticsearch_data_instances: 2			# Elasticsearch-Data 인스턴스 수
elasticsearch_data_vm_type: "medium"		# Elasticsearch-Data VM 종류
elasticsearch_data_network: "default"		# Elasticsearch-Data 네트워크
elasticsearch_data_persistent_disk_type: "30GB"	# Elasticsearch-Data 영구 Disk 종류

# KIBANA
kibana_azs: ["z5"]				# Kibana 가용 존
kibana_instances: 1				# Kibana 인스턴스 수
kibana_vm_type: "medium"			# Kibana VM 종류
kibana_network: "default"			# Kibana 네트워크
kibana_persistent_disk_type: "5GB"		# Kibana 영구 Disk 종류

# INGESTOR
ingestor_azs: ["z4", "z6"]			# Ingestor 가용 존
ingestor_instances: 2				# Ingestor 인스턴스 수
ingestor_vm_type: "medium"			# Ingestor VM 종류
ingestor_network: "default"			# Ingestor 네트워크
ingestor_persistent_disk_type: "10GB"		# Ingestor 영구 Disk 종류

# LS-ROUTER
ls_router_azs: ["z4"]			    	# LS-Router 가용 존
ls_router_instances: 1		  		# LS-Router 인스턴스 수
ls_router_vm_type: "small"			# LS-Router VM 종류
ls_router_network: "default"			# LS-Router 네트워크
```


deploy.sh을 실행하여 logsearch를 설치 한다.

```
$ cd ~/workspace/paasta-5.0/deployment/monitoring-deployment/paasta-monitoring
$ sh deploy-logsearch.sh
```

logsearch가 설치 완료 되었음을 확인한다.
```
$ bosh –e {director_name} vms
```
![PaaSTa_logsearch_vms_5.0]

[PaaSTa_logsearch_vms_5.0]:./images/logsearch_5.0.png
