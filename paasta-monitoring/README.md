## Table of Contents
1. [문서 개요](#1)
2. [PaaS-TA 5.0 Monitoring 설치 파일 다운로드](#2)
3. [PaaS-TA Monitoring 설치환경](#3)
4. [PaaS-TA Monitoring 설치](#4)
  - 4.1. [paasta-monitoring.yml](#5)
  - 4.2. [deploy-paasta-monitoring.sh](#6)
  - 4.3. [common_vars.yml](#7)
  - 4.3. [paasta-monitoring-vars.yml](#8)
5. [PaaS-TA Monitoring Dashboard 접속](#9)


## <div id='1'/>1. Pre-requsite

1. PaaS-TA 5.0 Monitoring을 설치 하기 위해서는 BOSH 설치과정에서 언급한 것 처럼 관련 deployment, release, stemcell을 PaaS-TA 사이트에서 다운로드 받아 정해진 경로에 복사 해야 한다.
2. PaaS-TA 5.0이 설치되어 있어야 하며, Monitoring Agent가 설치되어 있어야 한다.
3. BOSH Login이 되어 있어야 한다.

## <div id='2'/>2.	PaaS-TA 5.0 Monitoring 설치 파일 다운로드

> **[설치 파일 다운로드 받기](https://paas-ta.kr/download/package)**

> **[PaaS-TA Monitoring Source Github](https://github.com/PaaS-TA/PaaS-TA-Monitoring)**

PaaS-TA 사이트에서 [PaaS-TA 설치 릴리즈] 파일을 다운로드 받아 ${HOME}/workspace/paasta-5.0/release 이하 디렉토리에 압축을 푼다. 압축을 풀면 아래 그림과 같이 ${HOME}/workspace/paasta-5.0/release/paasta-monitoring 이하 디렉토리가 생성되며 이하에 릴리즈 파일(tgz)이 존재한다.

![PaaSTa_release_dir_5.0]

## <div id='3'/>3. PaaS-TA Monitoring 설치환경

${HOME}/workspace/paasta-5.0/deployment/monitoring-deployment 이하 디렉토리에는 paasta-monitoring, paasta-pinpoint-monitoring 디렉토리가 존재한다. Logsearch는 Log agent에서 발생한 Log정보를 수집하여 저장하는 Deployment이다. paasta-monitoring은 PaaS-TA VM에서 발생한 Metric 정보를 수집하여 Monitoring을 실행한다.

```
$ cd ${HOME}/workspace/paasta-5.0/deployment/monitoring-deployment
```

## <div id='4'/>4.	PaaS-TA Monitoring 설치

PaaS Monitoring을 위해서 paasta-monitoring이 설치되어야 한다. 

```
$ cd ${HOME}/workspace/paasta-5.0/deployment/monitoring-deployment/paasta-monitoring
```

### <div id='5'/>4.1.	paasta-monitoring.yml
paasta-monitoring.yml에는 Redis, InfluxDB(metric_db), MariaDB, Monitoring-WEB, Monitoring-Batch에 대한 명세가 있다.

```
---
name: paasta-monitoring

addons:
- name: bpm
  jobs:
  - name: bpm
    release: bpm

stemcells:
- alias: default
  os: ((stemcell_os))
  version: ((stemcell_version))

releases:
- name: paasta-monitoring-release
  sha1: 458773bc0973336447cf227828f17cce57906d14 
  version: "5.0"
  url: http://45.248.73.44/index.php/s/42RtMHzoNmpWbSZ/download
- name: bpm
  sha1: 44ffa71e70adfb262655253662c83148581ac970
  url: http://45.248.73.44/index.php/s/bMDXYCEQ85dMt6o/download
  version: '1.1.0'
- name: redis
  version: '14.0.1'
  url: http://45.248.73.44/index.php/s/FMwXoWTPK9YtSCJ/download
  sha1: fd4a6107e1fb8aca1d551054d8bc07e4f53ddf05
- name: influxdb
  version: '1.5.1'
  url: http://45.248.73.44/index.php/s/LDwdpizbw8fecZQ/download
  sha1: 2337d1f26f46100b8d438b50b71e300941da74a2


instance_groups:
- name: redis
  azs: ((redis_azs))
  instances: ((redis_instances))
  vm_type: ((redis_vm_type))
  stemcell: default
  persistent_disk: 10240
  networks:
  - name: ((redis_network))
    static_ips:
    - ((redis_ip))
 
  jobs:
  - name: redis
    release: redis
    properties:
      password: ((redis_password))
- name: sanity-tests
  azs: ((sanity_tests_azs))
  instances: ((sanity_tests_instances))
  lifecycle: errand
  vm_type: ((sanity_tests_vm_type))
  stemcell: default
  networks: [{name: ((sanity_tests_network))}]
  jobs:
  - name: sanity-tests
    release: redis

- name: influxdb
  azs: ((influxdb_azs))
  instances: ((influxdb_instances))
  vm_type: ((influxdb_vm_type))
  stemcell: default
  persistent_disk_type: ((influxdb_persistent_disk_type))
  networks:
  - name: ((influxdb_network))
    static_ips:
    - ((metric_url)) 

  jobs:
  - name: influxdb
    release: influxdb
    properties:
      influxdb:
        database: cf_metric_db
        user: root
        password: root
        replication: 1
        ips: 127.0.0.1
  - name: chronograf
    release: influxdb

- name: mariadb
  azs: ((mariadb_azs))
  instances: ((mariadb_instances))
  vm_type: ((mariadb_vm_type)) 
  stemcell: default
  persistent_disk_type: ((mariadb_persistent_disk_type))
  networks:
  - name: ((mariadb_network))
    static_ips: 
    - ((mariadb_ip))
  jobs:
  - name: mariadb
    release: paasta-monitoring-release
    properties:
      mariadb:
        port: ((mariadb_port))
        admin_user:
          password: '((mariadb_password))'

- name: monitoring-batch
  azs: ((monitoring_batch_azs))
  instances: ((monitoring_batch_instances))
  vm_type: ((monitoring_batch_vm_type)) 
  stemcell: default
  networks:
  - name: ((monitoring_batch_network))
  jobs:
  - name: monitoring-batch
    release: paasta-monitoring-release
    consumes:
      influxdb: {from: influxdb}
    properties:
      monitoring-batch:
        influxdb:
          url: ((metric_url)):8086
        db:
          ip: ((mariadb_ip))
          port: ((mariadb_port))
          username: ((mariadb_username))
          password: ((mariadb_password))
        paasta:
          cell_prefix: ((paasta_cell_prefix))
        bosh:
          url: ((bosh_url))
          password: ((bosh_client_admin_secret))
          director_name: ((director_name))
          paasta:
            deployments: ((paasta_deploy_name))
        mail:
          smtp:
            url: ((smtp_url))
            port: ((smtp_port))
          sender:
            name: ((mail_sender))
            password: ((mail_password))
          resource:
            url: ((resource_url))
          send: ((mail_enable))
          tls: ((mail_tls_enable))
        redis:
          url: ((redis_ip)):6379
          password: ((redis_password))
        paasta:
          apiurl: http://api.((system_domain))
          uaaurl: https://uaa.((system_domain))
          username: ((paasta_admin_username))
          password: ((paasta_admin_password))

- name: caas-monitoring-batch
  azs: ((caas_monitoring_batch_azs))
  instances: ((monitoring_batch_instances))
  vm_type: ((caas_monitoring_batch_vm_type))
  stemcell: default
  networks:
  - name: ((caas_monitoring_batch_network))
  jobs:
  - name: caas-monitoring-batch
    release: paasta-monitoring-release
    consumes:
      influxdb: {from: influxdb}
    properties:
      caas-monitoring-batch:
        db:
          ip: ((mariadb_ip))
          port: ((mariadb_port))
          username: ((mariadb_username))
          password: ((mariadb_password))
        mail:
          smtp:
            url: ((smtp_url))
            port: ((smtp_port))
          sender:
            name: ((mail_sender))
            password: ((mail_password))
          resource:
            url: ((resource_url))
          send: ((mail_enable))
          tls: ((mail_tls_enable))
        public:
          url: ((monitoring_api_url)):8080

- name: saas-monitoring-batch
  azs: ((saas_monitoring_batch_azs))
  instances: ((saas_monitoring_batch_instances))
  vm_type: ((saas_monitoring_batch_vm_type))
  stemcell: default
  networks:
  - name: ((saas_monitoring_batch_network))
  jobs:
  - name: saas-monitoring-batch
    release: paasta-monitoring-release
    consumes:
      influxdb: {from: influxdb}
    properties:
     saas-monitoring-batch:
        db:
          ip: ((mariadb_ip))
          port: ((mariadb_port))
          username: ((mariadb_username))
          password: ((mariadb_password))
        mail:
          smtp:
            url: ((smtp_url))
            port: ((smtp_port))
          sender:
            name: ((mail_sender))
            password: ((mail_password))
          resource:
            url: ((resource_url))
          send: ((mail_enable))
          tls: ((mail_tls_enable))
        pinpoint:
          url: ((saas_monitoring_url)):8079

- name: monitoring-web
  azs: ((monitoring_web_azs))
  instances: ((monitoring_web_instances))
  vm_type: ((monitoring_web_vm_type)) 
  stemcell: default
  networks:
  - name: ((monitoring_web_network))
    default: [dns, gateway]
  - name: ((public_network_name))
    static_ips: [((monitoring_api_url))]

  jobs:
  - name: monitoring-web
    release: paasta-monitoring-release
    properties:
      monitoring-web:
        db:
          ip: ((mariadb_ip))
          port: ((mariadb_port))
          username: ((mariadb_username))
          password: ((mariadb_password))
        influxdb:
          url: http://((metric_url)):8086
        paasta:
          system_domain: ((system_domain))
        bosh:
          ip: ((bosh_url))
          password: ((bosh_client_admin_secret))
          director_name: ((director_name))
        redis:
          url: ((redis_ip)):6379
          password: ((redis_password))
        time:
          gap: ((utc_time_gap))
        prometheus:
          url: ((prometheus_ip)):30090
        kubernetes:
          url: ((kubernetes_ip)):8443
          token: ((kubernetes_token))
        pinpoint:
          url: ((saas_monitoring_url)):8079
        pinpointWas:
          url: ((pinpoint_was_ip)):8080
        caasbroker:
          url: ((cassbroker_ip)):3334
        system:
          type: ((system_type))

variables:
- name: redis_password
  type: password

update:
  canaries: 1
  canary_watch_time: 1000-180000
  max_in_flight: 1
  serial: true
  update_watch_time: 1000-180000

```

### <div id='6'/>4.2.	deploy-paasta-monitoring.sh
```
bosh -e {director_name} -n -d paasta-monitoring deploy paasta-monitoring.yml  \
	-o use-public-network-openstack.yml \
	-o use-compiled-releases-paasta-monitoring.yml \
	-l paasta-monitoring-vars.yml \
	-l ../../common/common_vars.yml
```
### <div id='7'/>4.3.	common_vars.yml
```
# BOSH
bosh_url: "10.0.1.6"				# BOSH URL ('bosh env' 명령어를 통해 확인 가능)
bosh_client_admin_id: "admin"			# BOSH Client Admin ID
bosh_client_admin_secret: "ert7na4jpewscztsxz48"	# BOSH Client Admin Secret

# PAAS-TA
system_domain: "61.252.53.246.xip.io"		# Domain (xip.io를 사용하는 경우 HAProxy Public IP와 동일)
paasta_admin_username: "admin"			# PaaS-TA Admin Username
paasta_admin_password: "admin"			# PaaS-TA Admin Password
uaa_client_admin_secret: "admin-secret"		# UAAC Admin Client에 접근하기 위한 Secret 변수
uaa_client_portal_secret: "clientsecret"	# UAAC Portal Client에 접근하기 위한 Secret 변수

# MONITORING
metric_url: "10.0.161.101"			# Monitoring InfluxDB IP
syslog_address: "10.0.121.100"            	# Logsearch의 ls-router IP
syslog_port: "2514"                          	# Logsearch의 ls-router Port
syslog_transport: "relp"                        # Logsearch Protocol
monitoring_api_url: "61.252.53.241"        	# Monitoring-WEB의 Public IP
saas_monitoring_url: "61.252.53.248"	   	# Pinpoint HAProxy WEBUI의 Public IP
```


### <div id='8'/>4.3. paasta-monitoring-vars.yml	
deploy-paasta-monitoring.sh의 –v 의 inception_os_user_name, system_domain 및 director_name을 시스템 상황에 맞게 설정한다.

```
# SERVICE VARIABLE
inception_os_user_name: "ubuntu"	
mariadb_ip: "10.0.161.100"		# MariaDB VM Private IP
mariadb_port: "3306"			# MariaDB Port
mariadb_username: "root"		# MariaDB Root 계정 Username
mariadb_password: "password"		# MariaDB Root 계정 Password
director_name: "micro-bosh"		# BOSH Director 명
resource_url: "resource_url"		# TBD
paasta_deploy_name: "paasta"		# PaaS-TA Deployment 명
paasta_cell_prefix: "cell"		# PaaS-TA Cell 명
smtp_url: "smtp.naver.com"		# SMTP Server URL
smtp_port: "587"			# SMTP Server Port
mail_sender: "aaa@naver.com"		# SMTP Server Admin ID
mail_password: "aaaa"			# SMTP Server Admin Password
mail_enable: "true"			# Alarm 발생시 Mail전송 여부
mail_tls_enable: "true"			# SMTP 서버 인증시 TLS모드인경우 true
redis_ip: "10.0.121.101"		# Redis Private IP
redis_password: "password"		# Redis 인증 Password
utc_time_gap: "9"			# UTC Time Zone과 Client Time Zone과의 시간 차이
public_network_name: "vip"		# Monitoring-WEB Public Network Name
system_type: "PaaS,CaaS,SaaS"		# 모니터링 할 환경 선택
prometheus_ip: "10.0.121.122"		# Kubernates의 prometheus-prometheus-prometheus-oper-prometheus-0 Pod의 Node IP
kubernetes_ip: "10.0.0.124"		# Kubernates의 서비스 API IP
pinpoint_was_ip: "10.0.0.122"		# Pinpoint HAProxy WEBUI Private IP
cassbroker_ip: "52.141.6.113"		# CaaS 서비스 로그인 인증 처리를 위한 API IP
kubernetes_token: "eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJtb25pdG9yaW5nLWFkbWluLXRva2VuLWQ0OXc3Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6Im1vbml0b3JpbmctYWRtaW4iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI4MDkwNTU5Yy0wYzE2LTExZWEtYjZiYi0wMDIyNDgwNTk4NzciLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06bW9uaXRvcmluZy1hZG1pbiJ9.ZKPWJLo0LFXY9ZpW7nGlTBLJYDNL7MFB9X1i4JoEn8jPLsCQhG3lvzTjh7420lvoP5hWdV0SpsMMfZnV2WFFUWaQkYcnKhB2qsVX_xOd45gm2IfI-f1QmxcAspoGY_r8kC-vX9L4oTLA5sJTI5m_RIiuckVGcVR0OeWB5NtUFz0-iCpQRfuy9LYH0NCEEopfDji-T0Pxta8S1n8YyxVwYKpZE0PvT9H9ZVNUUAt2Z_l4B0akP6G3O6t53Xvp_l8DXzxRFXTw3sHPvvea_Uv3QbGcFkH-gNHBeG9-F8C8NMcSlCUeyAGfxZlpsdRFMB01Wh6RZzvUqeS8Kc-8Csp_jw"	# Kubernetes 서비스 API Request 호출시 Header(Authorization) 인증을 위한 Token값

# STEMCELL
stemcell_os: "ubuntu-xenial"		# Stemcell OS
stemcell_version: "315.36"		# Stemcell Version


# REDIS
redis_azs: ["z4"]			# Redis 가용 존
redis_instances: 1			# Redis 인스턴스 수
redis_vm_type: "small"			# Redis VM 종류
redis_network: "default"		# Redis 네트워크

# SANITY-TEST
sanity_tests_azs: ["z4"]		# Sanity-Test 가용 존
sanity_tests_instances: 1		# Sanity-Test 인스턴스 수
sanity_tests_vm_type: "small"		# Sanity-Test VM 종류
sanity_tests_network: "default"		# Sanity-Test 네트워크

# INFLUXDB
influxdb_azs: ["z5"]			# InfluxDB 가용 존
influxdb_instances: 1			# InfluxDB 인스턴스 수
influxdb_vm_type: "large"		# InfluxDB VM 종류
influxdb_network: "default"		# InfluxDB 네트워크
influxdb_persistent_disk_type: "10GB"	# InfluxDB 영구 Disk 종류

# MARIADB
mariadb_azs: ["z5"]			# MariaDB 가용 존
mariadb_instances: 1			# MariaDB 인스턴스 수
mariadb_vm_type: "medium"		# MariaDB VM 종류
mariadb_network: "default"		# MariaDB 네트워크
mariadb_persistent_disk_type: "5GB"	# MariaDB 영구 Disk 종류

# MONITORING-BATCH
monitoring_batch_azs: ["z6"]		# Monitoring-Batch 가용 존
monitoring_batch_instances: 1		# Monitoring-Batch 인스턴스 수
monitoring_batch_vm_type: "small"	# Monitoring-Batch VM 종류
monitoring_batch_network: "default"	# Monitoring-Batch 네트워크

# CAAS-MONITORING-BATCH
caas_monitoring_batch_azs: ["z6"]	# CAAS-Monitoring-Batch 가용 존
caas_monitoring_batch_instances: 1	# CAAS-Monitoring-Batch 인스턴스 수
caas_monitoring_batch_vm_type: "small"	# CAAS-Monitoring-Batch VM 종류
caas_monitoring_batch_network: "default"	# CAAS-Monitoring-Batch 네트워크

# SAAS-MONITORING-BATCH
saas_monitoring_batch_azs: ["z6"]	# SAAS-Monitoring-Batch 가용 존
saas_monitoring_batch_instances: 1	# SAAS-Monitoring-Batch 인스턴스 수
saas_monitoring_batch_vm_type: "small"	# SAAS-Monitoring-Batch VM 종류
saas_monitoring_batch_network: "default"	# SAAS-Monitoring-Batch 네트워크

# MONITORING-WEB
monitoring_web_azs: ["z7"]		# Monitoring-WEB 가용 존
monitoring_web_instances: 1		# Monitoring-WEB 인스턴스 수
monitoring_web_vm_type: "small"		# Monitoring-WEB VM 종류
monitoring_web_network: "default"	# Monitoring-WEB 네트워크
```


Note: 
1) MariaDB, InfluxDB, Redis VM은 사용자가 직접 IP를 지정한다. IP 지정시 paasta-monitoring.yml의 AZ와 cloud-config의 Subnet이 일치하는 IP대역내에 IP를 지정한다.
2) bosh_url: BOSH 설치시 설정한 BOSH Private IP
3) bosh_password: BOSH Admin Password로 BOSH Deploy시 생성되는 BOSH Admin Password를 입력해야 한다. 
${HOME}/workspace/paasta-5.0/deployment/paasta-deployment/bosh/{iaas}/creds.yml
creds.yml
admin_password: xxxxxxxxx 
4) smtp_url: SMTP Server IP (PaaS-TA를 설치한 시스템에서 사용가능한 SMTP 서버 IP
5) monit_public_ip: Monitoring WEB의 Public IP로 외부에서 Monitoring 화면에 접속하기 위해 필요한 외부 IP(Public IP 필요)
6) system_domain: PaaS-TA를 설치 할때 설정한 system_domain을 입력한다.
7) pinpoint_ip는 설지한 pinpoint_haproxy_webui Public IP를 지정한다.
8) pinpoint_was_ip는 설치한 pinpoint_haproxy_webui 내부 IP를 지정한다
9) prometheus_ip는 Kubernetes의 prometheus-prometheus-prometheus-oper-prometheus-0 Pod의 Node ip를 지정한다.
    <br>
   참조) [3.6.4. prometheus-prometheus-prometheus-oper-prometheus-0 POD의 Node IP를 확인한다.](#19-5)   
10) kubernetes_ip는 Kubernetes의 서비스 API IP를 지정한다.   
   참조) [3.6.5. Kubernetes API URL serverAddress를 확인한다.](#19-6)
11) kubernetes_token는 Kubernetes 서비스 API를 Request 호출할 수 있도록 Header에 설정하는 인증 토큰값을 지정한다.
   참조) [3.6.6. Kubernetes API Request 호출시 Header(Authorization) 인증을 위한 Token값을 확인한다.](#19-7) 
12) cassbroker_ip는 CaaS 서비스 로그인 인증 처리를 위한 API IP를 지정한다.        

deploy-paasta-monitoring.sh을 실행하여 PaaS-TA Monitoring을 설치 한다
```
$ cd ${HOME}/workspace/paasta-5.0/deployment/monitoring-deployment/paasta-monitoring
$ deploy-paasta-monitoring.sh
```

PaaS-TA Monitoring이 설치 완료 되었음을 확인한다.
```
$ bosh –e {director_name} vms
```
![PaaSTa_monitoring_vms_5.0]


## <div id='9'/>5. PaaS-TA Monitoring Dashboard 접속
 
 http://{monitoring_api_url}:8080/public/login.html 에 접속하여 회원 가입 후 Main Dashboard에 접속한다.

 Login 화면에서 회원 가입 버튼을 클릭한다.

 ![PaaSTa_monitoring_login_5.0]


member_info에는 사용자가 사용할 ID/PWD를 입력하고 하단 paas-info에는 PaaS-TA admin 권한의 계정을 입력한다. PaaS-TA deploy시 입력한 admin/pwd를 입력해야 한다. 입력후 [인증수행]를 실행후 Join버튼을 클릭하면 회원가입이 완료된다.

 ![PaaSTa_monitoring_join_5.0]

PaaS-TA Monitoring Main Dashboard 화면

 ![PaaSTa_monitoring_main_dashboard_5.0]

[IaaSTa_Monit_architecure_Image]:./images/iaas-archi.png
[PaaSTa_Monit_architecure_Image]:./images/monit_architecture.png
[Caas_Monit_architecure_Image]:./images/caas_monitoring_architecture.png
[Saas_Monit_architecure_Image]:./images/saas_monitoring_architecture.png
[PaaSTa_Monit_collect_architecure_Image]:./images/collect_architecture.png
[CaaS_Monit_collect_architecure_Image]:./images/caas_collect_architecture.png
[SaaS_Monit_collect_architecure_Image]:./images/saas_collect_architecture.png
[PaaSTa_release_dir_5.0]:./images/paasta-release_5.0.png
[PaaSTa_logsearch_vms_5.0]:./images/logsearch_5.0.png
[PaaSTa_monitoring_vms_5.0]:./images/paasta-monitoring_5.0.png

[PaaSTa_monitoring_login_5.0]:./images/monit_login_5.0.png
[PaaSTa_monitoring_join_5.0]:./images/member_join_5.0.png
[PaaSTa_monitoring_main_dashboard_5.0]:./images/monit_main_5.0.png

[PaaSTa_paasta_container_service_vms]:./images/paasta-container-service-vms.png
[PaaSTa_paasta_container_service_pods]:./images/paasta-container-service-pods.png
[PaaSTa_paasta_container_service_nodes]:./images/paasta-container-service-nodes.png
[PaaSTa_paasta_container_service_kubernetes_api]:./images/paasta-container-service-kubernetes-api.png
[PaaSTa_paasta_container_service_kubernetes_token]:./images/paasta-container-service-kubernetes-token.png

