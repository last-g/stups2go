FROM registry.opensource.zalan.do/stups/ubuntu:15.10-14

RUN apt-get update && apt-get install -y golang

COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]
