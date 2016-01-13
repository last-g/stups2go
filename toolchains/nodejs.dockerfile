FROM zalando/python:3.5.0-4

# newer nodejs
RUN curl -sL https://deb.nodesource.com/setup_5.x | bash -

# general tools
RUN apt-get install -y nodejs build-essential git

# upgrade npm to a sane version
RUN npm i -g npm

COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]
