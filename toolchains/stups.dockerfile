FROM zalando/python:3.5.0-3

RUN pip3 install stups scm-source awscli jq

WORKDIR /work
COPY switch-user.sh /switch-user.sh
ENTRYPOINT /switch-user.sh
