FROM registry.opensource.zalan.do/stups/ubuntu:15.10-24

RUN apt-get update && apt-get install -y git make

RUN curl https://storage.googleapis.com/golang/go1.6.1.linux-amd64.tar.gz -o /tmp/go1.6.1.linux-amd64.tar.gz && \
    echo '6d894da8b4ad3f7f6c295db0d73ccc3646bce630e1c43e662a0120681d47e988 /tmp/go1.6.1.linux-amd64.tar.gz' > /tmp/go1.6.1.linux-amd64.tar.gz.sha256sum && \
    sha256sum --check /tmp/go1.6.1.linux-amd64.tar.gz.sha256sum && \
    tar -C /usr/local -xzf /tmp/go1.6.1.linux-amd64.tar.gz && \
    rm /tmp/go1.6.1.linux-amd64.tar.gz


# keep our environment even after doing "su"
ENV PATH /usr/local/go/bin:$PATH
RUN echo "ENV_PATH PATH=$PATH" >> /etc/login.defs

COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]
