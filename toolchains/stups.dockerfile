FROM zalando/python:3.5.0-4

RUN apt-get update && apt-get install -y jq git
RUN pip3 install stups scm-source awscli

RUN curl -L https://github.com/jwilder/docker-squash/releases/download/v0.2.0/docker-squash-linux-amd64-v0.2.0.tar.gz -o /tmp/docker-squash.tar.gz \
    && tar -C /usr/local/bin -xzvf /tmp/docker-squash.tar.gz \
    && rm /tmp/docker-squash.tar.gz

COPY login-pierone.py /usr/bin/login-pierone

COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]
