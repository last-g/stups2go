FROM zalando/ubuntu:15.10-2

# newer nodejs
RUN curl -sL https://deb.nodesource.com/setup_5.x | bash -

# general tools
RUN apt-get install -y nodejs build-essential

# upgrade npm to a sane version
RUN npm i -g npm

WORKDIR /work
COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]
