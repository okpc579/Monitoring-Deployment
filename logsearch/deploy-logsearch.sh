#!/bin/bash

bosh -e micro-bosh -n -d logsearch deploy logsearch-deployment.yml \
	-o use-compiled-releases-logsearch.yml \
	-l logsearch-vars.yml \
	-l ../../common/common_vars.yml
