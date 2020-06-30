#!/bin/bash

bosh -e micro-bosh -d paasta -n deploy paasta-deployment-monitoring.yml \
	-o operations/use-compiled-releases.yml \
	-o operations/use-haproxy.yml \
	-o operations/use-haproxy-public-network-vsphere.yml \
	-o operations/use-compiled-releases-haproxy.yml \
	-o operations/use-postgres.yml \
	-o operations/use-compiled-releases-postgres.yml \
	-o operations/rename-network-and-deployment.yml \
	-o paasta-addon/paasta-monitoring.yml \
	-o paasta-addon/use-compiled-releases-monitoring-agent.yml \
	-o operations/addons/enable-component-syslog.yml \
	-o operations/addons/use-compiled-releases-syslog.yml \
	-l vsphere-vars.yml \
	-l ../common/common_vars.yml
