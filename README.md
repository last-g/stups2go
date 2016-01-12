# stups2go

[Go Continuous Delivery](http://www.go.cd/) service based on the
[STUPS infrastructure](https://stups.io).

WORK IN PROGRESS; ABSOLUTELY NOT FINISHED

## Target Audience

You are working with a [STUPS infrastructure](https://stups.io) and you need
a flexible and powerful continuous delivery tool. You are advanced in operating
servers and you know how your delivery pipeline has to be structured.

This appliance provides a raw, mostly unconfigured
[Go Continuous Delivery](http://www.go.cd/) setup. This appliance's goal is to
prepare integration with STUPS infrastructures (like authnz, Pier One support,
senza deployments, auto scaling). It makes no assumptions how you want to
structure your delivery pipelines or with which technologies you want to work.
Continuous delivery pipelines differ greatly for each and every project and
this is why you get raw administration access to set up everything to your
needs.

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
be able to accidentally influence your production systems (like exhausting
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


### General initialization

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

    $ aws iam create-role --role-name go-server-ebs-role \
                          --assume-role-policy-document file://./server/volume-trust.json
    $ aws iam put-role-policy --role-name go-server-ebs-role \
                              --policy-name go-server-ebs-policy \
                              --policy-document file://./server/volume-policy.json
    $ aws iam create-instance-profile --instance-profile-name go-server-ebs-profile
    $ aws iam add-role-to-instance-profile --instance-profile-name go-server-ebs-profile \
                                           --role-name go-server-ebs-role

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
                            --iam-instance-profile "Name=go-server-ebs-profile" \
                            --user-data file://./server/format-volume.yaml

You can now check in the logs of the server, if your EBS was properly
formatted. It might take a while until the output is available:

    $ aws ec2 get-console-output --instance-id <previous instance ID> | jq -r .Output

If everything looks good, terminate this instance:

    $ aws ec2 terminate-instances --instance-ids <previous instance ID>

Now your one-time, initial setup is done. The following topics show how to
provision your actual Go server and your Go agents.

### Deploying Go server

In order to integrate properly with your OAuth2 environment, you need to
register this deployment as an application in Kio. Go to YourTurn, register
the app, setup your mint bucket and assign your app the `application.read`
and `application.write` permission.

In order to deploy a Go server, you can use the predefined
[Senza template](server/senza-go-server.yaml). It takes the
following parameters:

* DockerImage
  * go-server Docker image to use. It is recommended to use this official
    Docker image which you can figure out with this command:
    `curl -s https://registry.opensource.zalan.do/teams/stups/artifacts/go-server/tags | jq "sort_by(.created)"`
* HostedZone
  * The hosted zone name in which to create the Go server's domain. Given a
    hosted zone name like `myteam.example.org`, the definition will create a
    domain called `delivery.myteam.example.org` pointing to the Go server's
    elastic load balancer. You can display all configured hosted zones with
    the following command: `aws route53 list-hosted-zones | jq ".HostedZones[].Name"`
* SSLCertificateId
  * The Go server is accessible only via SSL for security reasons. The
    definition will bootstrap an elastic load balancer using the SSL
    certificate specified here. The SSL certificate has to cover the above
    generated delivery domain. To find out your SSL certificate's IDs,
    execute the following command: `aws iam list-server-certificates`.
* AvailabilityZone
  * An EBS volume is always tied to an availability zone. This means, the
    Go server also has to run in this zone.
* InstanceType
  * With the instance type, you control costs and performance of your running
    Go server.
    [See Amazon's list of instance types](https://aws.amazon.com/ec2/instance-types/).
    TODO figure out good, recommended sizing for InstanceType.
* AccessTokenUrl
  * The "access token" endpoint of your OAuth2 provider. Something similar to
    `https://example.org/oauth2/access_token`.
* TeamServiceUrl
  * The URL of your deployed team service.
* Teams
  * Comma separated list of teams that should be included in your user search.
* ApplicationId
  * The application id of your registered Kio application.
* MintBucket
  * Your mint bucket, where your application credentials are synced to.

The following parameters are optional:

* Files
  * Comma separated list of <file>:<base64 content> tuples.
* ScalyrKey:
  * Optional key for scalyr logging.
* LogentriesKey:
  *Description: Optional key for logentries logging.
* AppdynamicsApplication:
  * Description: Optional AppDynamics application name.

An example deployment might look like that:

```bash
$ senza create server/senza-go-server.yaml server \
    DockerImage=registry.opensource.zalan.do/stups/go-server:<latest version> \
    HostedZone=myteam.example.org \
    SSLCertificateId=arn:aws:iam::1232342423:server-certificate/myteam-example-org \
    AvailabilityZone=eu-west-1a \
    InstanceType=c4.large \
    AccessTokenUrl=https://example.org/oauth2/access_token \
    TeamServiceUrl=https://teams.example.org \
    Teams=myteam,mypartnerteam \
    ApplicationId=my-go-appliance \
    MintBucket=my-stups-mint-bucket-name \
    ScalyrKey=1234567890abc1234567890 # optional
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

#### First steps

* [Add a new user](http://www.go.cd/documentation/user/current/configuration/managing_users.html)
  to the system, matching your username. This new user should be enabled and
  have administrative permissions by default.
  * Due to a current bug in the Go server, you have to enable the
    authentication system by [setting the path to your password file](http://www.go.cd/documentation/user/current/resources/images/user_authentication_password_file.png)
    to `/dev/null`.
* [Setup auto registration](http://www.go.cd/documentation/user/current/advanced_usage/agent_auto_register.html)
  in your Go server for Go agents and save your key. Note to generate a good
  random key!
* [Configure environments](http://www.go.cd/documentation/user/current/configuration/managing_environments.html)
  that you need. For this setup, create an environment `prod` and an environment `test`.
* [Read through the whole Go documentation](http://www.go.cd/documentation/user/current/configuration/index.html)
  how to properly configure your server. This appliance did not do any
  configurations for you. Add the users that need access, configure roles,
  assign them, configure pipelines etc.
* If you need additional plugins in your Go server, you have to create a new
  Docker image based on the general one. You can then just copy all necessary
  plugins to `/` like `/foobar-plugin.jar` and those will automatically be
  picked up on boot.
* Hint: You can use AWS SES SMTP server for sending notification mails.

### Go Agents

Deploying Go agents is a little bit more elaborate, since they can differ between usecases 
and your environments.

#### Customize your Go agent

It is not foreseeable whatever technology you use, so this appliance expects
you to build your own agent based on the one provided here. An example
Dockerfile could be build like that for a typical Java environment:

```
FROM registry.opensource.zalan.do/stups/go-agent:<agent version>
RUN apt-get install -y maven npm
```

A typical Clojure environment could look like that:

```
FROM registry.opensource.zalan.do/stups/go-agent:<agent version>
RUN curl https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein > /usr/local/bin/lein \
        && chmod +x /usr/local/bin/lein \
        && su - go -c "lein --version"
```

And obviously you can combine whatever you need at your builds like that:

```
FROM registry.opensource.zalan.do/stups/go-agent:<agent version>

# install whatever you need like Apache Maven or NPM with NodeJS
RUN apt-get install -y maven npm

# and in addition also Leiningen for compiling Clojure
RUN curl https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein > /usr/local/bin/lein \
        && chmod +x /usr/local/bin/lein \
        && su - go -c "lein --version"
```

Note that Docker and the STUPS tooling is preinstalled on the default agent.

#### Builder agents

Builder agents are meant to be deployed in a non-production AWS account. Those
should do the main work like compiling, testing and packaging your artifacts.
They can also do big integration tests with the resources of the test account
without accidentally affecting your production systems. Make sure you switched
your account to your test account with `mai login ...`.

At first, you need to open your mint bucket to your test account, in order to
be able to upload Docker images later on. Read about cross-account access
[on this page](http://docs.aws.amazon.com/AmazonS3/latest/dev/example-walkthroughs-managing-access-example2.html).
The policy to attach to your bucket should look look similar to that:

```json
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Sid": "GoAgentCredentialsAccess",
         "Effect": "Allow",
         "Principal": {
            "AWS": "arn:aws:iam::<your-test-account-id>:root"
         },
         "Action": [
            "s3:GetObject",
            "s3:ListBucket"
         ],
         "Resource": [
            "arn:aws:s3:::<your-mint-bucket-name>",
            "arn:aws:s3:::<your-mint-bucket-name>/<your-application-id>/*"
         ]
      }
   ]
}
```

#### Deployer agents

Deployer agents have access to your production system and should mainly focus
on all your deployment steps. They will have permission to actually deploy
and tear down your production servers.

TODO define senza template

#### Deploying Go agents

The go-agent templates take similar arguments as the go-server. The extra
arguments are those:

* GoServerDomain
  * The domain where you find your Go server e.g. `delivery.example.org`.
* GoAgentRegistrationKey
  * The preshared registration key for Go agents to automatically register
    with your Go server.
* GoAgentEnvironments
  * The environment to announce to the Go server. As an example, this could
    be `test` or `prod`.
* GoAgentCount
  * Your agents will run in an auto scaling group but currently there is no
    metric to truly automatically scale. You can manage the count of agents
    dynamically with your ASG.

An example deployment might look like this:

```bash
$ senza create agent/senza-go-agent.yaml agent \
    DockerImage=<your custom agent image> \
    GoServerDomain=delivery.example.org \
    GoAgentRegistrationKey=<your generated preshared key> \
    GoAgentEnvironments=test \
    GoAgentCount=10 \
    InstanceType=m3.medium \
    ApplicationId=my-go-appliance \
    AccessTokenUrl=https://example.org/oauth2/access_token \
    MintBucket=my-stups-mint-bucket-name \
    ScalyrKey=1234567890abc1234567890 # optional
```

## Pipeline tooling

To centralize several common tasks, we created some toolchains to predefine some workloads. These can be used by Pipelines:

* scm-source.json creation
  * `/tools/run registry.opensource.zalan.do/stups/toolchain-stups:<version> -- scm-source -f <target_scm_source_json_file>`
    * use this to create your scm-source.json, which is needed to identify the code base the docker image will use.
* pierone login
  * `/tools/run registry.opensource.zalan.do/stups/toolchain-stups:<version> -e OAUTH2_ACCESS_TOKEN_URL=https://example.org/oauth2/access_token -- login-pierone <pierone url>`
    * Use this command in your pipeline before you pull or push images from your
    PierOne registry. This will generate a Docker configuration with
    appropriate authentication.

## Build this repository

```bash
$ ./prepare-deps.sh

$ cd server
$ docker build -t registry.opensource.zalan.do/stups/go-server:1.0 .
$ cd ..

$ cd agent
$ docker build -t registry.opensource.zalan.do/stups/go-agent:1.0 .
$ cd ..
```

Run containers locally for testing:

```bash
$ docker run --name go-server \
             -p 8153:8153 \
             -d registry.opensource.zalan.do/stups/go-server:1.0

$ docker run --link go-server:go-server-link \
             -v /var/run/docker.sock:/var/run/docker.sock \
             -d registry.opensource.zalan.do/stups/go-agent:1.0
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

