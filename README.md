# stups2go

[Go Continuous Delivery](http://www.go.cd/) service based on the [STUPS infrastructure](https://stups.io).

WORK IN PROGRESS; ABSOLUTLY NOT FINISHED

## Usage

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

## TODO

* Add OpenIG as authentication layer and provide STUPS compliant default
  configuration. Add own OpenIG-expecting authentication plugin to determine
  username and role from OpenIG auth.

## Known Limitations

* Database and configuration storage relies solely on AWS EBS. Do snapshots on your own!
* http://www.go.cd/documentation/user/current/advanced_usage/agent_auto_register.html

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

