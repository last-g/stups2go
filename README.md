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


### Initializing main EBS

The default setup requires the main EBS to exist. With the following steps, you
can easily set one up as necessary.

With the AWS CLI, you can create the volume itself. The following is a
reasonable example:

    $ aws ec2 create-volume --size 100 \
                            --availability-zone eu-west-1a \
                            --volume-type gp2 \
                            --encrypted

Use the resulting "VolumeId" to attach a name tag to the EBS, so your Go
server is able to find it:

    $ aws ec2 create-tags --resources <the previous VolumeId> \
                          --tags "Key=Name,Value=go-server"

In order to give your servers access to this disk, you need a proper IAM
instance profile. [This document](server/volume-policy.json) is an example
policy you can adapt. Create it with the following commands:

    $ aws iam create-role --role-name go-server \
                          --assume-role-policy-document file://./server/volume-trust.json
    $ aws iam put-role-policy --role-name go-server \
                              --policy-name go-server-policy \
                              --policy-document file://./server/volume-policy.json
    $ aws iam create-instance-profile --instance-profile-name go-server
    $ aws iam add-role-to-instance-profile --instance-profile-name go-server \
                                           --role-name go-server

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
                            --iam-instance-profile "Name=go-server" \
                            --user-data file://./server/format-volume.yaml

You can now checks in the logs of the server, if your EBS was properly
formatted. It might take a while until the output is available:

    $ aws ec2 get-console-output --instance-id <previous instance ID> | jq -r .Output

If everything looks good, terminate this instance:

    $ aws ec2 terminate-instances --instance-ids <previous instance ID>

Now your one-time, initial setup is done. The following topics show how to
provision your actual Go server and your Go agents.

### Deploying Go server

No senza template available yet.

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

