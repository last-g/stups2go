FROM zalando/openjdk:8u66-b17-1-3

RUN apt-get update && apt-get install -y maven

COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]
