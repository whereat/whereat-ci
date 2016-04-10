# To deploy Concourse to BOSH Cluster on AWS:

## Understand the BOSH/Concourse architecture (Optional)

To really understand this, it's probably worth spending some time with the docs for both [Concourse](https://concourse.ci/introduction.html) and [Bosh](http://bosh.io/docs), particularly this [excellent tutorial](http://mariash.github.io/learn-bosh/).

However, those are a bit hairy, so we've done our best to provide the Cliff Notes version below. (Improvements or requests for clarification welcome!)

* The most common installation of Concourse runs on a Virtual Private Cloud
* A VPC is a cluster of servers on a private subnet on AWS
* Some of those servers run a platform called BOSH
* The Bosh Director is responsible for provisioning the rest of the servers on the VPD, including the ones that actually run Concourse
* Concourse itself has a "director"-like server (provisioned by the Bosh Director) that is responsible for coordinating all of the build activity in the various pipelines you provide to it
* Both Bosh and Concourse are provisioned through providing `yml` manifests to Bosh
* Bosh is bootstrapped with a command-line program called `bosh-init`
* Once bosh is installed, Concourse can be provisioned and updated by running the `bosh` CLI targeted at a specific Bosh installation (in our case the VPC on AWS we bootstrapped with `bosh-init`)
* Provisioning Concourse involves uploading a "stemcell" (base operating system) and "releases" (software we want to run on those operating systems), then configuring them through more `yml` files
* Configuring and running builds achieved through a CLI called `fly`, which creates pipelines on the concourse server according to specifications in more `yml` files, then runs them and displays there results on the command line

## Prepare the AWS Environment

Follow steps 2 and on in this [guide](http://bosh.io/docs/init-aws.html#prepare-aws), writing down the values the guide suggests you substitute into your manifest -- you'll need those in the next step!

## Set Environment Variables

Paste the below export statements into your `~/.bashrc` file (or another file that is sourced from `~/.bashrc`). Replace all instances of `???` with the values you gathered above.

Feel free to delete or replace occurrences of `WHEREAT_`, just note that you'll also need to make the same deletions or replacements in all `___-dist.yml` files for the deploy scripts to work.

```shell
export WHEREAT_BOSH_AWS_ACCESS_KEY_ID=???
export WHEREAT_BOSH_AWS_ACCESS_KEY_SECRET=???
export WHEREAT_BOSH_ELASTIC_IP=???
export WHEREAT_BOSH_SUBNET_ID=???
export WHEREAT_BOSH_SECURITY_GROUP=???
export WHEREAT_CONCOURSE_POSTGRES_PASSWORD=???
```

## Provision the Concourse Box

```shell
$ cd ${WHEREAT_ROOT}/whereat-ci/scripts
$ ./deploy-bosh.sh
$ ./provision-bosh.sh
$ ./deploy-concourse.sh
```

## Configure a Load Balancer with SSL Termination

We're almost there! Now we just need to provide an interface to allow the outside world to reach the private subnet hosting our Concourse cluster!

* [Get a free x509 certificate from AWS]()
  * you'll likely want a wilcard certificate
  * ie: if your website is `example.com`, get a cert for `*.example.com`
  * this way, you can put your load balancer at `ci.examples.com` and have it covered by the cert
* [Create the load balancer](http://bosh.io/docs/setup-aws.html)
  * name it `elb-concourse` (or what you will)
  * create it inside your bosh VPC
  * provide the following listener configurations:

    | Load Balancer Protocol | Load Balancer Port | Instance Protocol | Instance Port |
    |---|---|---|---|
    | HTTPS | 443 | HTTPS | 443 |
    | TCP | 2222 | TCP | 2222 |

  * Add the subnet associated with your bosh VPC (adding only one subnet is fine!)
  * create a `elb-concourse` security group with these inbound rules:

    | Type | Protocol | Port Range | Source |
    |---|---|---|---|
    | HTTPS | TCP | 443 | 0.0.0.0/0 |
    | Custom TCP Rule | TCP | 2222 | 0.0.0.0/0 |

  * use the x509 certificate you just created for SSL termination
  * associate the ELB with your `web/0` instance
* create a `concourse` security group with following inbound rules:

    | Type | Protocol | Port Range | Source |
    |---|---|---|---|
    | HTTP | TCP | 80 | <id for elb-concourse security group> |
    | Custom TCP Rule | TCP | 8080 | <id for elb-concourse security group> |
    | Custom TCP Rule | TCP | 2222 | <id for elb-concourse security group> |

* create a `CNAME` DNS record on your domain pointing to the ELB
  * given the url `somereallylongurl.amazonaws.com` and the domain `example.com`, a successful DNS entry would look like this:

    ```shell
    ci.example.com. 1800 IN CNAME somereallylongurl.amazonaws.com.
    ```

## Go use it!

If everything above worked, you should be able to go to `ci.example.com` and see a blue screen prompting you to install some pipelines!
