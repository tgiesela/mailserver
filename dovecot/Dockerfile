FROM debian:latest
MAINTAINER Tonny Gieselaar <tgiesela@gmail.com>

ENV DEBIAN_FRONTEND="noninteractive" \
    TERM="xterm" \
    APTLIST="cron wget jq locales nano net-tools apt-utils wget procps dnsutils iputils-ping" \
    UPDATE="apt update && apt -y upgrade" \
    CLEANUP="apt -y autoremove && apt -y clean && rm -rf /var/lib/apt/lists"

RUN eval ${UPDATE} && \
        apt -qy install --no-install-recommends ${APTLIST} && \
    locale-gen --no-purge nl_NL.UTF-8 en_US.UTF-8 && \
    eval ${CLEANUP}

# install dovecot
RUN eval ${UPDATE} && \
        apt install -y dovecot-imapd dovecot-pop3d dovecot-ldap dovecot-lmtpd && \
    eval ${CLEANUP}

RUN cp -R /etc/dovecot/conf.d/ /etc/dovecot/conf.d.saved/
ADD config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD config/default/conf.d/ /etc/dovecot/conf.d/
ADD config/ldap/conf.d/ /etc/dovecot/conf.d/ldap/

# Container scripts
ADD --chmod=755 scripts/init.sh /init.sh

EXPOSE 143 993 110 995
ENTRYPOINT ["/init.sh"]
CMD ["app:start"]

