FROM registry.opensource.zalan.do/stups/node:6.1-28

# general tools
RUN apt-get install -y git

COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]
