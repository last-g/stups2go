# registry.opensource.zalan.do/stups/go-agent

FROM zalando/openjdk:8u66-b01-5-1
MAINTAINER Zalando SE

# keep image updated
RUN apt-get update && apt-get upgrade -y

# install Go debian package
COPY *.deb /
RUN dpkg -i /*.deb && rm /*.deb

# general utilities a very basic agent needs for all STUPS builds
RUN apt-get install -y git python3-setuptools docker.io
RUN easy_install3 pip && pip install stups-senza

# prepare configuration
RUN echo "GO_SERVER=\${CONFIG_GO_SERVER}" >> /etc/default/go-agent
RUN echo "GO_SERVER_PORT=\${CONFIG_GO_SERVER_PORT}" >> /etc/default/go-agent
RUN echo "DAEMON=N" >> /etc/default/go-agent

# working dir
VOLUME /var/lib/go-agent

# our own script with runtime preparations
COPY run.sh /run.sh
CMD /run.sh
