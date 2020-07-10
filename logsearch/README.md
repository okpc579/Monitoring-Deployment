## Table of Contents

1\. [개요](#1)  
2\. [Logsearch 설치](#2)  
　2.1. [Prerequisite](#3)  
　2.2. [설치 파일 다운로드](#4)  
　2.3. [Logsearch 설치 환경설정](#5)   
　　● [logsearch-vars.yml](#7)  
　　● [deploy-logsearch.sh](#8)  
　2.4. [Logsearch 설치](#9)  
　2.5. [Logsearch 설치 - 다운로드 된 PaaS-TA Release 파일 이용 방식](#10)  
　2.6. [서비스 설치 확인](#11)


## <div id='1'/>1. 개요

본 문서(Logsearch 설치 가이드)는 PaaS-TA Monitoring을 설치하기 앞서 BOSH와 PaaS-TA의 VM Log 수집을 위하여 BOSH 2.0을 이용하여 Logsearch를 설치하는 방법을 기술하였다.

## <div id='2'/>2. Logsearch 설치
### <div id='3'/>2.1 Prerequisite

1. BOSH 설치가 되어있으며, BOSH Login이 되어 있어야 한다.
2. cloud-config와 runtime-config가 업데이트 되어있는지 확인한다.
3. Stemcell 목록을 확인하여 서비스 설치에 필요한 Stemcell(ubuntu xenial 315.36)이 업로드 되어 있는 것을 확인한다.


> cloud-config 확인  
> $ bosh -e {director-name} cloud-config  
> runtime-config 확인  
> $ bosh -e {director-name} runtime-config  
> stemcell 확인  
> $ bosh -e {director-name} stemcells  


### <div id='4'/>2.2. 설치 파일 다운로드

- Logsearch를 설치하기 위한 deployment가 존재하지 않는다면 다운로드 받는다
```
$ cd ${HOME}/workspace/paasta-5.0/deployment
$ git clone https://github.com/PaaS-TA/Common-Deployment.git common
$ git clone https://github.com/PaaS-TA/PaaS-TA-Deployment.git paasta-deployment
```


### <div id='5'/>2.3. Logsearch 설치 환경설정

PaaS-TA VM Log수집을 위해서는 Logsearch가 설치되어야 한다. 

```
$ cd ${HOME}/workspace/paasta-5.0/deployment/monitoring-deployment/paasta-monitoring
```

### <div id='7'/>● logsearch-vars.yml

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

### <div id='8'/>● deploy-logsearch.sh

deploy.sh의 –v 의 inception_os_user_name, router_ip, system_domain 및 director_name을 시스템 상황에 맞게 설정한다.  
system_domain은 PaaS-TA 설치시 설정했던 system_domain을 입력하면 된다.  
router_ip는 ls-router가 설치된 azs에서 정의한 cider값의 적당한 IP를 지정한다.

```
bosh –e {director_name} -d logsearch deploy logsearch-deployment.yml \				
	-o use-compiled-releases-logsearch.yml \
	-l logsearch-vars.yml \
	-l ../../common/common_vars.yml
```

### <div id='9'/>2.3. Logsearch 설치
deploy.sh을 실행하여 logsearch를 설치 한다.

```
$ cd ~/workspace/paasta-5.0/deployment/monitoring-deployment/paasta-monitoring
$ sh deploy-logsearch.sh
```
### <div id='10'/>2.3. Logsearch 설치 - 다운로드 된 PaaS-TA Release 파일 이용 방식
deploy.sh을 실행하여 logsearch를 설치 한다.

```
$ cd ~/workspace/paasta-5.0/deployment/monitoring-deployment/paasta-monitoring
$ sh deploy-logsearch.sh
```

### <div id='11'/>2.7. 서비스 설치 확인
logsearch가 설치 완료 되었음을 확인한다.
```
$ bosh –e {director_name} vms
```
![PaaSTa_logsearch_vms_5.0]

[PaaSTa_logsearch_vms_5.0]:./images/logsearch_5.0.png
