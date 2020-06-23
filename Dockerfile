FROM ubuntu

RUN apt-get update && \
    apt-get install -y \
        openssl

COPY openssl.cnf /etc/ssl/openssl.cnf

WORKDIR /ssl
VOLUME /ssl
CMD ["bash"]