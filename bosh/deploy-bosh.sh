#!/bin/bash

pushd

source ~/.bashrc
cd ${WHEREAT_ROOT}/whereat-ci/bosh/

echo 'Creating bosh manifest...'
cat bosh-dist.yml > bosh.yml
file="../bosh/bosh.yml" ../insert-secrets.sh

echo 'Deploying bosh...'
bosh-init deploy bosh.yml && 
    yes admin | bosh target ${WHEREAT_BOSH_ELASTIC_IP} &&
    bosh vms &&
    rm bosh.yml
    
popd
