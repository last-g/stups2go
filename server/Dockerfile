# registry.opensource.zalan.do/stups/go-server

FROM zalando/openjdk:8u66-b17-1-2
MAINTAINER Zalando SE

# keep image updated
RUN apt-get update && apt-get upgrade -y

# install Go debian package
COPY *.deb /
RUN apt-get install -y unzip git subversion && dpkg -i /*.deb && rm /*.deb

# the http port of Go
EXPOSE 8153

# the main data storage
VOLUME /data

# runtime files
COPY log4j.properties /log4j.properties

# add STUPS extensions
COPY authentication-plugin/target/go-stups-authentication-plugin.jar /

# some tools
COPY extract-files.sh /extract-files.sh

# run our bootstrap script
COPY run.sh /run.sh
CMD /run.sh
