BOSH 설치시 SYSLOG, MONITORING-AGENT 추가하고 COMMON_VARS에 이하의 내용을 추가하는걸 언급
metric_url: "10.0.161.101"			# 모니터링 InfluxDB IP (e.g. 00.00.000.000:8059)
syslog_address: "10.0.121.100"            	# Logsearch의 ls-router IP
syslog_port: "2514"                          	# Logsearch의 ls-router Port
syslog_transport: "relp"                        # Logsearch Protocol
monitoring_api_url: "61.252.53.241"        	# Monitoring-WEB의 Public IP
saas_monitoring_url: "61.252.53.248"	   	# Pinpoint HAProxy WEBUI의 Public IP

PaaS-TA 모니터링에 대한 걸 설치(Stemcell) Stemcell 315.36임을 확인 

paasta-addon/paasta-monitoring.yml
operations/addons/enable-component-syslog.yml
metric_url=10.0.15.11
syslog_address="10.0.10.15"
syslog_port="2514"
syslog_custom_rule="if ($msg contains "DEBUG") then stop"
syslog_fallback_servers=[]

옵션파일과 common 파일에 저런 값이 들어가있는질 확인
   
   
logsearch 설치

Pinpoint설치
CaaS설치
IaaS설치

PaaS-TA Monitoring 설치
