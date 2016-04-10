#!/bin/bash

pushd

source ~/.bashrc
cd ${WHEREAT_ROOT}/whereat-ci/bosh/

echo 'Creating cloud-config manifest...'
cat cloud-config-dist.yml > cloud-config.yml
file="../bosh/cloud-config.yml" ../insert-secrets.sh

echo 'Provisioning bosh director...'
bosh update cloud-config cloud-config.yml &&
    bosh cloud-config &&
    rm cloud-config.yml

bosh upload stemcell https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3215 &&
    bosh stemcells

popd
