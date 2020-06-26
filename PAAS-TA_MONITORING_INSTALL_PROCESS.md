## Table of Contents

1. [PaaS-TA Monitoring 설치 순서](#1)
  * [BOSH 설치](#2)
  * [common_vars.yml 설정](#3)
  * [통합 Monitoring을 적용한 PaaS-TA 5.0 설치](#4)
  * [Logsearch 설치](#5)
  * [Pinpoint 설치](#6)
  * [Container Service 설치](#7)
  * [Monasca 설치](#8)

# <div id='1'/>1. PaaS-TA Monitoring 설치 순서

본 문서(PaaS-TA Monitoring 설치 가이드)는 PaaS-TA 5.0 환경기준으로 PaaS-TA Monitoring 설치를 위한 가이드를 제공한다.

최종적으로 PaaS-TA Monitoring 설치를 위해서는 우선 PaaS-TA Monitoring 설치시에 IaaS의 네트워크에 맞춰서 후에 설치할 PaaS-TA Monitoring InfluxDB IP인 metric_url와 Logsearch의 ls-router IP인 syslog_address를 미리 정해둘 필요가 있다.

metric_url와 syslog_address를 정했다면 PaaS-TA Monitoring 옵션과 필요한 변수를 포함하여 BOSH을 설치한다.
옵션과 필요한 변수는 하단의 [BOSH 설치](https://github.com/okpc579/Monitoring-Deployment/blob/master/PAAS-TA_MONITORING_INSTALL_PROCESS.md#2)를 확인하거나
[BOSH 설치 가이드](https://github.com/okpc579/PaaS-TA-Deployment/blob/master/bosh-deployment/README.md)에서 확인할 수 있다.

BOSH의 설치가 끝면 BOSH을 설치할때 정보와 [common_vars.yml을 설정](https://github.com/okpc579/Monitoring-Deployment/blob/master/PAAS-TA_MONITORING_INSTALL_PROCESS.md#12-common_varsyml-%EC%84%A4%EC%A0%95)해야 한다.

common_vars.yml 작성이 끝나면 PaaS-TA Monitoring 옵션과 필요한 변수를 포함하여 BOSH을 설치한다.
옵션과 필요한 변수는 하단의 [통합 Monitoring을 적용한 PaaS-TA 5.0 설치](https://github.com/okpc579/Monitoring-Deployment/blob/master/PAAS-TA_MONITORING_INSTALL_PROCESS.md#4)를 확인하거나
[통합 Monitoring을 적용한 PaaS-TA 5.0 설치 가이드](https://github.com/okpc579/Monitoring-Deployment/blob/master/paasta-deployment/README.md)에서 확인할 수 있다.

그리고 PaaS-TA VM 들을 확인하기 위한 Logsearch를 설치하고 
Monitoring을 할 환경을 정하여 옵션으로 Pinpoint(SaaS), Container Service(CaaS), Monasca(IaaS)를 설치 후 PaaS-TA Monitoring을 설치한다.



## <div id='2'/>1.1. BOSH 설치

deploy-openstack.sh 에 모니터링 관련 옵션인<br>
syslog.yml, use-compiled-releases-syslog.yml(선택), paasta-addon/paasta-monitoring-agent.yml을 추가하고<br>
각 {IaaS}-vars.yml에 하단의 정보를 추가해야 한다.<br>
metric_url:		# PaaS-TA Monitoring InfluxDB IP<br>
syslog_address: 	# Logsearch의 ls-router IP<br>
syslog_port: 		# Logsearch의 ls-router Port( e.g. "2514")<br>
syslog_transport: 	# Logsearch Protocol( e.g. "relp")




## <div id='3'/>1.2. common_vars.yml 설정

bosh_url: "10.0.1.6"
bosh_client_admin_id: "admin"			# BOSH Client Admin ID
bosh_client_admin_secret: "ert7na4jpewscztsxz48"	# BOSH Client Admin Secret

system_domain: "61.252.53.246.xip.io"		# Domain (xip.io를 사용하는 경우 haproxy_public_ip와 동일)
paasta_admin_username: "admin"			# PaaS-TA Admin Username
paasta_admin_password: "admin"			# PaaS-TA Admin Password
uaa_client_admin_secret: "admin-secret"		# UAAC Admin Client에 접근하기 위한 Secret 변수
uaa_client_portal_secret: "clientsecret"	# UAAC Portal Client에 접근하기 위한 Secret 변수

metric_url: "10.0.161.101"			# Monitoring InfluxDB IP
syslog_address: "10.0.121.100"            	# Logsearch의 ls-router IP
syslog_port: "2514"                          	# Logsearch의 ls-router Port
syslog_transport: "relp"                        # Logsearch Protocol
monitoring_api_url: "61.252.53.241"        	# Monitoring-WEB의 Public IP
saas_monitoring_url: "61.252.53.248"	   	# Pinpoint HAProxy WEBUI의 Public IP


## <div id='4'/>1.3. PaaS-TA 설치


PaaS-TA 모니터링에 대한 걸 설치(Stemcell) Stemcell 315.36임을 확인 

paasta-addon/paasta-monitoring.yml
operations/addons/enable-component-syslog.yml
metric_url=10.0.15.11
syslog_address="10.0.10.15"
syslog_port="2514"
syslog_custom_rule="if ($msg contains "DEBUG") then stop"
syslog_fallback_servers=[]

옵션파일과 common 파일에 저런 값이 들어가있는질 확인
   

## <div id='5'/>1.4. Logsearch 설치

logsearch 설치

## <div id='6'/>1.5. Pinpoint 설치

Pinpoint설치

## <div id='7'/>1.6. CaaS 설치
CaaS설치

## <div id='8'/>1.7. Monasca 설치
IaaS설치


## <div id='9'/>1.8. PaaS-TA Monitoring 설치
PaaS-TA Monitoring 설치
