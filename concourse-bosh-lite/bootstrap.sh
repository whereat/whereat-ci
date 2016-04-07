#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

set -e

# Dependencies:
# bosh        [https://bosh.io/docs/bosh-cli.html]
# jq          [https://stedolan.github.io/jq/]
# fly         [https://concourse.ci/fly-cli.html]
# vagrant     [https://www.vagrantup.com/]
# vagrant-aws [https://github.com/mitchellh/vagrant-aws]

# Grant bosh config ownership to ubuntu, and create ssh keys
vagrant ssh -c 'sudo chown -R ubuntu ~/.bosh_config ~/tmp; [ ! -f /home/ubuntu/.ssh/id_rsa ] && ssh-keygen -N "" -f "/home/ubuntu/.ssh/id_rsa" || echo "Keys already setup" '

# This allows an external host to target bosh in the cloud
vagrant ssh -c 'sudo iptables -t nat -A PREROUTING -p tcp -d $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --dport 8080 -j DNAT --to 10.244.8.2:8080'

# Now we target our fresh installation of bosh-lite
# The default user is admin/admin according to https://bosh.io/docs/director-users.html#default
yes admin | bosh target $BOSH_AWS_ELASTIC_IP whereat-bosh-lite

# Use jq to detect matching releases of concourse and garden and upload them to the director
curl -s https://api.github.com/repos/concourse/concourse/releases/latest | jq -r ".assets[].browser_download_url" | xargs -L1 bosh -t whereat-bosh-lite upload release

# Upload the bosh-warden-boshlite stemcell
bosh -t whereat-bosh-lite upload stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent

# Deploy!
bosh -t whereat-bosh-lite deployment concourse.yml
bosh -t whereat-bosh-lite -n deploy
