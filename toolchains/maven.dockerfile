FROM registry.opensource.zalan.do/stups/openjdk:8u66-b17-1-17

RUN apt-get update && apt-get install -y maven

COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]
