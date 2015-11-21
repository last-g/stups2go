FROM zalando/python:3.5.0-3

RUN apt-get update && apt-get install -y jq git
RUN pip3 install stups scm-source awscli

COPY login-pierone.py /usr/bin/login-pierone

COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]
