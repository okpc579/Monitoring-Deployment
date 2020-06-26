## Table of Contents

1. [PaaS-TA Monitoring 설치 순서](#1)
  * [BOSH 설치](#2)
  * [common_vars.yml 설정](#3)
  * [PaaS-TA 설치](#4)
  * [Logsearch 설치](#5)
  * [Pinpoint 설치](#6)
  * [Container Service 설치](#7)
  * [Monasca 설치](#8)

# <div id='1'/>1. PaaS-TA Monitoring 설치 순서




## <div id='2'/>1.1. BOSH 설치

BOSH 설치시 SYSLOG, MONITORING-AGENT 추가하고 COMMON_VARS에 이하의 내용을 추가하는걸 언급
옵션
	-o syslog.yml \
	-o use-compiled-releases-syslog.yml \
	-o paasta-addon/paasta-monitoring-agent.yml \
metric_url: "10.0.161.101"			# 모니터링 InfluxDB IP
syslog_address: "10.0.121.100"            	# Logsearch의 ls-router IP
syslog_port: "2514"                          	# Logsearch의 ls-router Port
syslog_transport: "relp"                        # Logsearch Protocol

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
   

## <div id='4'/>1.4. Logsearch 설치

logsearch 설치

## <div id='5'/>1.5. Pinpoint 설치

Pinpoint설치

## <div id='6'/>1.6. CaaS 설치
CaaS설치

## <div id='7'/>1.7. Monasca 설치
IaaS설치


## <div id='8'/>1.8. PaaS-TA Monitoring 설치
PaaS-TA Monitoring 설치
