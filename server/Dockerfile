# registry.opensource.zalan.do/stups/go-server

FROM registry.opensource.zalan.do/stups/openjdk:8-28
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

# add extensions
COPY *.jar /

# some tools
COPY extract-files.sh /extract-files.sh

# adding scm-source.json
COPY scm-source.json /scm-source.json

# run our bootstrap script
COPY run.sh /run.sh
CMD /run.sh
