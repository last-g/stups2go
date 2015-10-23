FROM zalando/openjdk:8u45-b14-6
MAINTAINER Zalando SE

# keep image updated
RUN apt-get update && apt-get upgrade -y

# install Go debian package
COPY *.deb /
RUN apt-get install unzip && dpkg -i /*.deb && rm /*.deb

# prepare configuration
RUN echo "DAEMON=N" >> /etc/default/go-server

# the http port of Go
EXPOSE 8153

# working dir
VOLUME /var/lib/go-server

# run with predefined user
USER go
CMD /usr/share/go-server/server.sh
