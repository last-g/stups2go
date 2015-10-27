# registry.opensource.zalan.do/stups/go-server

FROM zalando/openjdk:8u66-b01-5-1
MAINTAINER Zalando SE

# keep image updated
RUN apt-get update && apt-get upgrade -y

# install Go debian package
COPY *.deb /
RUN apt-get install unzip && dpkg -i /*.deb && rm /*.deb

# the http port of Go
EXPOSE 8153

# the main data storage
VOLUME /data

# runtime files
COPY log4j.properties /log4j.properties

# run our bootstrap script
COPY run.sh /run.sh
CMD /run.sh
