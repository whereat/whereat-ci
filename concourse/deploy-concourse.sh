#!/bin/bash

pushd

source ~/.bashrc
cd ${WHEREAT_ROOT}/whereat-ci/concourse/

echo 'Uploading releases to bosh director...'
bosh upload release https://github.com/concourse/concourse/releases/download/v1.0.0/concourse-1.0.0.tgz &&
    bosh upload release https://github.com/concourse/concourse/releases/download/v1.0.0/garden-linux-0.335.0.tgz &&
    bosh releases

echo 'Creating concourse manifest...'
cat concourse-dist.yml > concourse.yml
file="../concourse/concourse.yml" ../insert-secrets.sh

echo 'Deploying concourse...'
bosh deployment concourse.yml
bosh deploy &&
    bosh deployments &&
    rm concourse.yml

popd

