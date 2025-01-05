FROM debian:bookworm-slim

WORKDIR /tmp

# download vcontrold
ADD --checksum=sha256:3f87fbdf1a4856b4aa561a9a54063c240add965d7605c253012b17972504984c \
    https://github.com/openv/vcontrold/releases/download/v0.98.12/vcontrold_0.98.12-16_armhf.deb /vcontrold.deb

# install dependencies and vcontrold
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y libxml2=2.9.14+dfsg-1.3~deb12u1 \
                       mosquitto-clients=2.0.11-1.2+deb12u1 \
                       jq=1.6-2.1 \
                       /vcontrold.deb && \
    rm -rf /var/lib/apt/lists/*

# cleanup
RUN rm /vcontrold.deb

# create some required folders.
RUN mkdir /config && \
    mkdir /app && \
    mkdir /log

# copy the required code files
COPY ./app /app
RUN chmod -R 555 /app

# set up non-root user
RUN groupadd -r vcontrold && useradd --no-log-init -r -g vcontrold vcontrold
USER vcontrold

VOLUME ["/config", "/log"]

CMD ["bash", "/app/startup.sh"]
