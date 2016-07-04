# registry.opensource.zalan.do/stups/go-agent

FROM registry.opensource.zalan.do/stups/openjdk:8-28
MAINTAINER Zalando SE

# shareable volumes for sub containers
VOLUME /var/lib/go-agent
VOLUME /var/go

# keep image updated
RUN apt-get update && apt-get upgrade -y

# create a 'worker' user for, and avoid automatic user creation by go
RUN useradd -u 909 -d $HOME -M -s /bin/bash worker

# install Go debian package
COPY *.deb /
RUN dpkg -i /*.deb && rm /*.deb

# general utilities a very basic agent needs for all STUPS builds
RUN apt-get install -y git subversion

# prepare configuration
RUN echo "GO_SERVER=\${STUPS_GO_SERVER_DOMAIN}" >> /etc/default/go-agent
RUN echo "GO_SERVER_PORT=9153" >> /etc/default/go-agent
RUN echo "DAEMON=N" >> /etc/default/go-agent

# add tooling
COPY tools /tools
COPY extract-files.sh /extract-files.sh

# adding scm-source.json
COPY scm-source.json /scm-source.json

# our own script with runtime preparations
COPY run.sh /run.sh
CMD /run.sh
