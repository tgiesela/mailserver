FROM ubuntu:16.04
MAINTAINER Tonny Gieselaar <tonny@devosverzuimbeheer.nl>

ENV DEBIAN_FRONTEND noninteractive

# install supervisord and some additional tools
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y supervisor \
        net-tools nano apt-utils wget rsyslog

# install fetchmail
RUN apt-get install -y fetchmail
# for testing only
RUN apt-get install -y telnet

ADD config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD config/fetchmailrc /etc/
# Container scripts
ADD scripts/init.sh /init.sh
RUN chmod 755 /init.sh

RUN apt-get clean

ENTRYPOINT ["/init.sh"]
CMD ["app:start"]

