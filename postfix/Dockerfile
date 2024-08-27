FROM debian:latest
MAINTAINER Tonny Gieselaar <tgiesela@gmail.com>

ENV DEBIAN_FRONTEND="noninteractive" \
    TERM="xterm" \
    APTLIST="cron wget jq locales nano net-tools apt-utils wget procps dnsutils iputils-ping iproute2" \
    UPDATE="apt update && apt -y upgrade" \
    CLEANUP="apt -y autoremove && apt -y clean && rm -rf /var/lib/apt/lists"

RUN eval ${UPDATE} && \
        apt -qy install --no-install-recommends ${APTLIST} && \
    locale-gen --no-purge nl_NL.UTF-8 en_US.UTF-8 && \
    eval ${CLEANUP}

# install postfix
RUN eval ${UPDATE} && \
        apt install -y postfix sasl2-bin postfix-pcre postfix-ldap libsasl2-modules && \
    eval ${CLEANUP}

ADD config/main.cf /etc/postfix/
ADD config/master.cf /etc/postfix/
ADD config/ldap_virtual_recipients.cf /etc/postfix/
ADD config/ldap_virtual_aliases.cf /etc/postfix/
ADD config/virtual_recipients.cf /etc/postfix/
ADD config/virtual_domains /etc/postfix/

# Container scripts
ADD --chmod=755 scripts/init.sh /init.sh

EXPOSE 25 587 465
ENTRYPOINT ["/init.sh"]
CMD ["app:start"]

