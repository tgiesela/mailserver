FROM debian:latest
MAINTAINER Tonny Gieselaar <tonny@devosverzuimbeheer.nl>

ENV DEBIAN_FRONTEND noninteractive

# install some additional tools
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y \
        net-tools nano apt-utils wget 

# install fetchmail
RUN apt-get install -y fetchmail
# for testing only
RUN apt-get install -y procps

# use git secret to reveal the contents of fetchmailrc and .netrc
# or create the files manually before you build
ADD config/fetchmailrc /etc/
ADD config/.netrc ~/
# Container scripts
ADD scripts/init.sh /init.sh
RUN chmod 755 /init.sh

RUN apt-get clean

ENTRYPOINT ["/init.sh"]
CMD ["app:start"]

