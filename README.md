# stups2go

[Go Continuous Delivery](http://www.go.cd/) service based on the
[STUPS infrastructure](https://stups.io).

WORK IN PROGRESS; ABSOLUTLY NOT FINISHED

## Architecture

This appliance will recommend and prepare you for the following architecture.
The Go server is the main control unit. It is your main way to deploy your
production servers and therefor has the permissions to do it. This is a very
critical and vulnerable piece in your infrastructure. That's why it runs in
your production account as it has the same criticality as your production
apps.

You should also setup a couple of Go agents which sole purpose is deploying
into your production account. They will not build artifacts or execute any
tests. This also means that those can be very tiny (t2.micro) instances.

Most real work will be done by "builder" Go agents in your testing account.
These have no access to the production servers, so that your tests shouldn't
be able to accdidentally influence your production systems (like exhausting
instance limits). They can be bought with Spot Fleet as they do not have
serious availability requirements. You can size the servers however you need
for your delivery pipelines.

![Architecture](https://docs.google.com/drawings/d/1GhGw85XLVYNCsOHy_mAW-AtGhXBcIhKA4Jce46EFQ4o/pub?w=473&h=305)

## Usage

Currently, the Go server requires a local disk as database. This implicates,
that the Go server cannot be set up for high availability. Fortunately, this
is not that critical for that part of the infrastructure. This appliance
solves the problem by using AWS EBS as the main database storage. You can
setup regular snappshotting for backups and also use encryption to have your
data encrypted at rest.


### General initilisation

The default setup requires the main EBS to exist. With the following steps, you
can easily set one up as necessary. Carefully review every command, especially
if you want to customize your deployment.

With the AWS CLI, you can create the volume itself. The following is a
reasonable example:

    $ aws ec2 create-volume --size 100 \
                            --availability-zone eu-west-1a \
                            --volume-type gp2 \
                            --encrypted

Use the resulting "VolumeId" to attach a name tag to the EBS, so your Go
server is able to find it:

    $ aws ec2 create-tags --resources <the previous VolumeId> \
                          --tags "Key=Name,Value=go-server-volume"

In order to give your servers access to this disk, you need a proper IAM
instance profile. [This document](server/volume-policy.json) is an example
policy you can adapt. Create it with the following commands:

    $ aws iam create-role --role-name go-server-role \
                          --assume-role-policy-document file://./server/volume-trust.json
    $ aws iam put-role-policy --role-name go-server-role \
                              --policy-name go-server-policy \
                              --policy-document file://./server/volume-policy.json
    $ aws iam create-instance-profile --instance-profile-name go-server-profile
    $ aws iam add-role-to-instance-profile --instance-profile-name go-server-profile \
                                           --role-name go-server-role

TODO you can be more strict in your policy document to only allow attaching
exactly your EBS.

The newly created EBS is a raw disk which is not formatted for now. We can use
[Taupage](http://docs.stups.io/en/latest/components/taupage.html)'s built-in
formatting functionality to bootstrap the disk:

    $ aws ec2 run-instances --image-id <a recent Taupage image> \
                            --subnet-id <a subnet ID in your chosen AZ> \
                            --placement "AvailabilityZone=eu-west-1a" \
			    --instance-type "t2.micro" \
                            --monitoring "Enabled=false" \
                            --iam-instance-profile "Name=go-server-profile" \
                            --user-data file://./server/format-volume.yaml

You can now check in the logs of the server, if your EBS was properly
formatted. It might take a while until the output is available:

    $ aws ec2 get-console-output --instance-id <previous instance ID> | jq -r .Output

If everything looks good, terminate this instance:

    $ aws ec2 terminate-instances --instance-ids <previous instance ID>

Now your one-time, initial setup is done. The following topics show how to
provision your actual Go server and your Go agents.

### Deploying Go server

In order to deploy a Go server, you can use the predefined
[Senza template](server/senza-go-server.yaml). It takes the
following parameters:

* DockerImage
  * go-server Docker image to use. It is recommended to use this official
    Docker image like `registry.opensource.zalan.do/stups/go-server:<latest version>`.
* HostedZone
  * The hosted zone name in which to create the Go server's domain. Given a
    hosted zone name like `myteam.example.org`, the definition will create a
    domain called `delivery.myteam.example.org` pointing to the Go server's
    elastic load balancer.
* SSLCertificateId
  * The Go server is accessible only via SSL for security reasons. The
    definition will bootstrap an elastic load balancer using the SSL
    certificate specified here. The SSL certificate has to cover the above
    generated delivery domain. To find out your SSL certificate's IDs,
    execute the following command: `aws iam list-server-certificates`.
* AvailabilityZone
  * An EBS volume is always tied to an availability zone. This means, the
    Go server also has to run in this zone. These settings have to match.
* InstanceType
  * With the instance type, you control costs and performance of your running
    Go server. One possibility might be `c4.large`.

TODO figure out good, recommended sizing for InstanceType

An example deployment might look like that:

```bash
$ senza create server/senza-go-server.yaml default \
    registry.opensource.zalan.do/stups/go-server:<latest version> \
    myteam.example.org \
    arn:aws:iam::1232342423:server-certificate/myteam-example-org \
    eu-west-1a \
    c4.large
```

This will now spin up the Go server for you with a proper production ready
setup.

Since this appliance currently only relies on a shared EBS volume, it is not
possible to run a high availability setup. This means, minor downtimes are
possible if the hosting server goes down. The deployed auto scaling group will
automatically spin up a new instance, so downtimes should be minimal like
a handful minutes.

But this also means that upgrades of the Go server will lead to short
downtimes. The update procedure itself is simple: First, you destroy the
running stack via `senza delete server/senza-go-server.yaml default`. Your
EBS is safe and unused now so you can just spin up a new stack as shown above
with a newer image. The new server will attach the shared EBS and proceed
working.

### Deploying Go agents

No senza template available yet.

## Build this repository

```bash
$ ./prepare-deps.sh

$ cd server
$ docker build -t go-server .
$ cd ..

$ cd agent
$ docker build -g go-agent .
$ cd ..
```

Run containers locally for testing:

```bash
$ docker run --name go-server \
             -p 8153:8153 \
             -d go-server

$ docker run --link go-server:go-server-link \
             -v /var/run/docker.sock:/var/run/docker.sock \
             -d go-agent
```

## Known Limitations

* Database and configuration storage relies solely on AWS EBS. Do snapshots on your own!

## License

Copyright © 2015 Zalando SE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

