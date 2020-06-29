## <div id='1'/>1. Pre-requsite

1. PaaS-TA 5.0 Monitoring을 설치 하기 위해서는 bosh 설치과정에서 언급한 것 처럼 관련 deployment, release, stemcell을 PaaS-TA 사이트에서 다운로드 받아 정해진 경로에 복사 해야 한다.
2. PaaS-TA 5.0이 설치되어 있어야 하며, monitoring Agent가 설치되어 있어야 한다.
3. BOSH login이 되어 있어야 한다.

## <div id='2'/>2.	PaaS-TA 5.0 Monitoring 설치 파일 다운로드

> **[설치 파일 다운로드 받기](https://paas-ta.kr/download/package)**

> **[PaaS-TA Monitoring Source Github](https://github.com/PaaS-TA/PaaS-TA-Monitoring)**

PaaS-TA 사이트에서 [PaaS-TA 설치 릴리즈] 파일을 다운로드 받아 ${HOME}/workspace/paasta-5.0/release 이하 디렉토리에 압축을 푼다. 압출을 풀면 아래 그림과 같이 ${HOME}/workspace/paasta-5.0/release/paasta-monitoring 이하 디렉토리가 생성되며 이하에 릴리즈 파일(tgz)이 존재한다.

![PaaSTa_release_dir_5.0]

## <div id='3'/>3. PaaS-TA Monitoring 설치환경

${HOME}/workspace/paasta-5.0/deployment/paasta-deployment-monitoring 이하 디렉토리에는 paasta-monitoring, paasta-pinpoint-monitoring 디렉토리가 존재한다. Logsearch는 logAgent에서 발생한 Log정보를 수집하여 저장하는 Deployment이다. paasta-monitoring은 PaaS-TA VM에서 발생한 Metric 정보를 수집하여 Monitoring을 실행한다.

```
$ cd ${HOME}/workspace/paasta-5.0/deployment/paasta-deployment-monitoring
```

## <div id='4'/>4.	PaaS-TA Monitoring 설치

PaaS Monitoring을 위해서 paasta-monitoring이 설치되어야 한다. 

```
$ cd ${HOME}/workspace/paasta-5.0/deployment/paasta-deployment-monitoring/paasta-monitoring
```

### <div id='5'/>4.1.	paasta-monitoring.yml
paasta-monitoring.yml에는 redis, influxdb(metric_db), mariadb, monitoring-web, monitoring-batch에 대한 명세가 있다.

```
---
name: paasta-monitoring                      # 서비스 배포이름(필수) bosh deployments 로 확인 가능한 이름

addons:
- name: bpm
  jobs:
  - name: bpm
    release: bpm

stemcells:
- alias: default
  os: ubuntu-xenial
  version: latest

releases:
- name: paasta-monitoring  # 서비스 릴리즈 이름(필수) bosh releases로 확인 가능
  version: latest                                              # 서비스 릴리즈 버전(필수):latest 시 업로드된 서비스 릴리즈 최신버전
  url: file:///home/((inception_os_user_name))/workspace/paasta-5.0/release/monitoring/monitoring-release.tgz 
- name: bpm
  sha1: 0845cccca348c6988debba3084b5d65fa7ca7fa9
  url: file:///home/((inception_os_user_name))/workspace/paasta-5.0/release/paasta/bpm-0.13.0-ubuntu-xenial-97.28-20181023-211102-981313842.tgz
  version: 0.13.0
- name: redis
  version: 14.0.1
  url: file:///home/((inception_os_user_name))/workspace/paasta-5.0/release/service/redis-14.0.1.tgz
  sha1: fd4a6107e1fb8aca1d551054d8bc07e4f53ddf05
- name: influxdb
  version: latest
  url: file:///home/((inception_os_user_name))/workspace/paasta-5.0/release/service/influxdb.tgz
  sha1: 2337d1f26f46100b8d438b50b71e300941da74a2


instance_groups:
- name: redis
  azs: [z4]
  instances: 1
  vm_type: small
  stemcell: default
  persistent_disk: 10240
  networks:
  - name: default
    default: [dns, gateway]
    static_ips:
    - ((redis_ip))
  - name: vip
    static_ips:
    - 115.68.151.177 
 
  jobs:
  - name: redis
    release: redis
    properties:
      password: ((redis_password))
- name: sanity-tests
  azs: [z4]
  instances: 1
  lifecycle: errand
  vm_type: small
  stemcell: default
  networks: [{name: default}]
  jobs:
  - name: sanity-tests
    release: redis

- name: influxdb
  azs: [z5]
  instances: 1
  vm_type: large
  stemcell: default
  persistent_disk_type: 10GB
  networks:
  - name: default
    default: [dns, gateway]
    static_ips:
    - ((influxdb_ip)) 
  - name: vip
    static_ips: 
    - 115.68.151.187

  jobs:
  - name: influxdb
    release: influxdb
    properties:
      influxdb:
        database: cf_metric_db                                        #InfluxDB default database
        user: root                                                                                              #admin account
        password: root                                                                                  #admin password
        replication: 1
        ips: 127.0.0.1                                                                                  #local I2
  - name: chronograf
    release: influxdb

- name: mariadb
  azs: [z5]
  instances: 1
  vm_type: medium 
  stemcell: default
  persistent_disk_type: 5GB
  networks:
  - name: default
    default: [dns, gateway]
    static_ips: ((mariadb_ip))
  - name: vip
    static_ips:
    - 115.68.151.188
  jobs:
  - name: mariadb
    release: paasta-monitoring
    properties:
      mariadb:
        port: ((mariadb_port))                                        #InfluxDB default database
        admin_user:
          password: '((mariadb_password))'                             # MARIA DB ROOT 계정 비밀번호

- name: monitoring-batch
  azs: [z6]
  instances: 1
  vm_type: small 
  stemcell: default
  networks:
  - name: default
  jobs:
  - name: monitoring-batch
    release: paasta-monitoring
    consumes:
      influxdb: {from: influxdb}
    properties:
      monitoring-batch:
        influxdb:
          url: ((influxdb_ip)):8086
        db:
          ip: ((mariadb_ip))
          port: ((mariadb_port))
          username: ((mariadb_username))
          password: ((mariadb_password))
        paasta:
          cell_prefix: ((paasta_cell_prefix))
        bosh:
          url: ((bosh_url))
          password: ((bosh_password))
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
          username: ((paasta_username))
          password: ((paasta_password))

- name: caas-monitoring-batch
  azs: [z6]
  instances: 1
  vm_type: small
  stemcell: default
  networks:
  - name: default
  jobs:
  - name: caas-monitoring-batch
    release: paasta-monitoring
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

- name: saas-monitoring-batch
  azs: [z6]
  instances: 1
  vm_type: small
  stemcell: default
  networks:
  - name: default
  jobs:
  - name: saas-monitoring-batch
    release: paasta-monitoring
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

- name: monitoring-web
  azs: [z6]
  instances: 1
  vm_type: small 
  stemcell: default
  networks:
  - name: default
    default: [dns, gateway]
  - name: vip
    static_ips: [((monit_public_ip))]

  jobs:
  - name: monitoring-web
    release: paasta-monitoring
    properties:
      monitoring-web:
        db:
          ip: ((mariadb_ip))
          port: ((mariadb_port))
          username: ((mariadb_username))
          password: ((mariadb_password))
        influxdb:
          url: http://((influxdb_ip)):8086
        paasta:
          system_domain: ((system_domain))
        bosh:
          ip: ((bosh_url))
          password: ((bosh_password))
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
          url: ((pinpoint_ip)):8079
        pinpointWas:
          url: ((pinpoint_was_ip)):8080
        caasbroker:
          url: ((cassbroker_ip)):3334

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
deploy-paasta-monitoring.sh의 –v 의 inception_os_user_name, system_domain 및 director_name을 시스템 상황에 맞게 설정한다.

```
bosh –e {director_name} -d paasta-monitoring deploy paasta-monitoring.yml  \
     -v inception_os_user_name=ubuntu \
     -v mariadb_ip=10.20.50.11 \  # mariadb vm private IP
     -v mariadb_port=3306 \      # mariadb port
     -v mariadb_username=root \  # mariadb root 계정
     -v mariadb_password=password \  # mariadb root 계정 password
     -v influxdb_ip=10.20.50.15 \   # influxdb vm private IP
     -v bosh_url=10.20.0.7 \        # bosh private IP
     -v bosh_password=2w87no4mgc9mtpc0zyus \  # bosh admin password
     -v director_name=micro-bosh \       # bosh director 명
     -v paasta_deploy_name=paasta \      # paasta deployment 명
     -v paasta_cell_prefix=cell \        # paasta cell 명
     -v paasta_username=admin \          # paasta admin 계정
     -v paasta_password=admin \          # paasta admin password
     -v smtp_url=127.0.0.1 \             # smtp server url
     -v smtp_port=25 \                   # smtp server port
     -v mail_sender=csupshin\            # smtp server admin id
     -v mail_password=xxxx\              # smtp server admin password
     -v mail_enable=flase \              # alarm 발생시 mail전송 여부
     -v mail_tls_enable=false \          # smtp서버 인증시 tls모드인경우 true
     -v redis_ip=10.20.40.11 \           # redis private ip
     -v redis_password=password \        # redis 인증 password
     -v utc_time_gap=9 \                 # utc time zone과 Client time zone과의 시간 차이
     -v monit_public_ip=xxx.xxx.xxx.xxx \ # 설치시 monitoring-web VM의 public ip
     -v system_domain={System_domain}    #PaaS-TA 설치시 설정한 System Domain
     -v prometheus_ip=35.188.183.252 \
     -v kubernetes_ip=211.251.238.234 \
     -v pinpoint_ip=101.55.50.216 \
     -v pinpoint_was_ip=10.1.81.123 \
     -v cassbroker_ip=13.124.44.35 \
     -v kubernetes_token=eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm........

```

Note: 
1)	mariadb, influxdb, redis vm은 사용자가 직접 ip를 지정한다. Ip 지정시 paasta-monitoring.yml의 az와 cloud-config의 subnet이 일치하는 ip대역내에 ip를 지정한다.
2)	bosh_url: bosh 설치시 설정한 bosh private ip
3)	bosh_password: bosh admin Password로 bosh deploy시 생성되는 bosh admin password를 입력해야 한다. 
~/workspace/paasta-5.0/deployment/bosh-deployment/{iaas}/creds.yml
creds.yml
admin_password: xxxxxxxxx 
4)	smtp_url: smtp Server ip (PaaS-TA를 설치한 시스템에서 사용가능한 smtp 서버 IP
5)	monit_public_ip: monitoring web의 public ip로 외부에서 Monitoring 화면에 접속하기 위해 필요한 외부 ip(public ip 필요)
6)	system_domain: paasta를 설치 할때 설정한 system_domain을 입력한다.
7) pinpoint_ip는 설지한 pinpoint_haproxy_webui public ip를 지정한다.
8) pinpoint_was_ip는 설치한 pinpoint_haproxy_webui 내부 ip를 지정한다
9) prometheus_ip는 Kubernetes의 prometheus-prometheus-prometheus-oper-prometheus-0 Pod의 Node ip를 지정한다.
    <br>
   참조) [3.6.4. prometheus-prometheus-prometheus-oper-prometheus-0 POD의 Node IP를 확인한다.](#19-5)   
10) kubernetes_ip는 Kubernetes의 서비스 API ip를 지정한다.   
   참조) [3.6.5. Kubernetes API URL serverAddress를 확인한다.](#19-6)
11) kubernetes_token는 Kubernetes 서비스 API를 Request 호출할 수 있도록 Header에 설정하는 인증 토큰값을 지정한다.
   참조) [3.6.6. Kubernetes API Request 호출시 Header(Authorization) 인증을 위한 Token값을 확인한다.](#19-7) 
12) cassbroker_ip는 CaaS 서비스 로그인 인증 처리를 위한 API ip를 지정한다.        

deploy-paasta-monitoring.sh을 실행하여 PaaS-TA Monitoring을 설치 한다
```
$ cd ${HOME}/workspace/paasta-5.0/deployment/paasta-deployment-monitoring/paasta-monitoring
$ deploy-paasta-monitoring.sh
```

PaaS-TA Monitoring이 설치 완료 되었음을 확인한다.
```
$ bosh –e {director_name} vms
```
![PaaSTa_monitoring_vms_5.0]


## <div id='7'/>5. PaaS-TA Monitoring dashboard 접속
 
 http://{monit_public_ip}:8080/public/login.html 에 접속하여 회원 가입 후 Main Dashboard에 접속한다.

 Login 화면에서 회원 가입 버튼을 클릭한다.

 ![PaaSTa_monitoring_login_5.0]


member_info에는 사용자가 사용할 ID/PWD를 입력하고 하단 paas-info에는 PaaS-TA admin 권한의 계정을 입력한다. PaaS-TA deploy시 입력한 admin/pwd를 입력해야 한다. 입력후 [인증수행]를 실행후 Join버튼을 클릭하면 회원가입이 완료된다.

 ![PaaSTa_monitoring_join_5.0]

PaaS-TA Monitoring main dashboard 화면

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

