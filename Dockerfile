# Original credit: https://github.com/jpetazzo/dockvpn

# fuck you, Smallest base image
FROM alpine:latest

# setup packages
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn iptables bash easy-rsa bridge bridge-utils && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

#

# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

# Prevents refused client connection because of an expired CRL
ENV EASYRSA_CRL_DAYS 3650

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

# add ovpn_* bash scripts
ADD bin /usr/local/bin/
RUN chmod a+x /usr/local/bin/*

# add bridge start script 
COPY up.sh /usr/share/up.sh
RUN chmod +x /usr/share/up.sh

# run customized start-script
CMD ["ovpn_run_tap"]
