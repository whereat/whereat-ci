#!/bin/bash

yes admin | bosh target ${WHEREAT_BOSH_LITE_ELASTIC_IP};
bosh deployment concourse-lite.yml;
bosh -n deploy;
