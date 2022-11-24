#FROM resin/rpi-raspbian:latest
FROM debian:latest
MAINTAINER Tonny Gieselaar <tonny@devosverzuimbeheer.nl>

ENV DEBIAN_FRONTEND noninteractive

# install supervisord and some additional tools
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y \
        net-tools nano apt-utils wget 

# install postfix
RUN apt-get install -y postfix sasl2-bin postfix-pcre postfix-ldap libsasl2-modules
# for testing only
RUN apt-get install -y telnet procps dnsutils iputils-ping

ADD config/main.cf /etc/postfix/
ADD config/master.cf /etc/postfix/
ADD config/ldap_virtual_recipients.cf /etc/postfix/
ADD config/ldap_virtual_aliases.cf /etc/postfix/
ADD config/virtual_domains /etc/postfix/

# Container scripts
ADD scripts/init.sh /init.sh
RUN chmod 755 /init.sh

RUN apt-get clean

EXPOSE 25 587 465
ENTRYPOINT ["/init.sh"]
CMD ["app:start"]

