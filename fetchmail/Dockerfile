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

# install fetchmail
RUN eval ${UPDATE} && \
        apt install -y fetchmail && \
        apt reinstall -y netbase && \
    eval ${CLEANUP}

# use git secret reveal to reveal the contents of fetchmailrc and .netrc
# or create the files manually before you build
ADD config/fetchmailrc /etc/
ADD config/.netrc /root/
# Container scripts
ADD --chmod=755 scripts/init.sh /init.sh

ENTRYPOINT ["/init.sh"]
CMD ["app:start"]

