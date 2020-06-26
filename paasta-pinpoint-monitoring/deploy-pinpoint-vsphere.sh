#!/bin/bash

echo 'y' | bosh -d paasta-pinpoint-service deploy paasta-pinpoint.yml\
	-o use-public-network-vsphere.yml \
	-l pinpoint-vars.yml \
	-l ../../common/common_vars.yml \
	-l pem.yml
