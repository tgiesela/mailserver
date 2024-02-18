#FROM resin/rpi-raspbian:latest
FROM debian:latest
MAINTAINER Tonny Gieselaar <tonny@devosverzuimbeheer.nl>

ENV DEBIAN_FRONTEND noninteractive

# install supervisord and some additional tools
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y supervisor \
        net-tools nano apt-utils wget

# install dovecot
RUN apt-get install -y dovecot-imapd dovecot-pop3d dovecot-ldap dovecot-lmtpd 

RUN cp -R /etc/dovecot/conf.d/ /etc/dovecot/conf.d.saved/
ADD config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD config/default/conf.d/ /etc/dovecot/conf.d/
ADD config/ldap/conf.d/ /etc/dovecot/conf.d/ldap/
RUN apt-get install -y procps
ADD scripts/init.sh /init.sh
RUN chmod 755 /init.sh

RUN apt-get clean

EXPOSE 143 993 110 995
ENTRYPOINT ["/init.sh"]
CMD ["app:start"]

