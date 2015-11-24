FROM zalando/python:3.5.0-3

# newer nodejs
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -

# general tools
RUN apt-get install -y nodejs build-essential

# upgrade npm to a sane version
RUN npm i -g npm

COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]
