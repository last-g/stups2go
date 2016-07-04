FROM registry.opensource.zalan.do/stups/openjdk:8-28

RUN apt-get update && apt-get install -y maven bzip2

COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]
