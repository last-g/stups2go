FROM zalando/python:3.5.0-3

RUN apt-get update && apt-get install -y jq
RUN pip3 install stups scm-source awscli

WORKDIR /work
COPY switch-user.sh /switch-user.sh
ENTRYPOINT /switch-user.sh
