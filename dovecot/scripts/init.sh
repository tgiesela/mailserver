#!/bin/bash

set -e
CERTFOLDER=/etc/ssl/dovecot
CACERT=${CERTFOLDER}/ssl-cert-snakeoil.pem
PRIVATEKEY=${CERTFOLDER}/mail.key
PUBLICCERT=${CERTFOLDER}/mailcert.pem

info () {
    echo "[INFO] $@"
}

generateCertificate() {
    mkdir -p ${CERTFOLDER}
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -subj "${CERTIFICATESUBJECT}" -keyout ${PRIVATEKEY} -out ${PUBLICCERT}
}
updatefile() {
    sed -i "s/<domain>/$DOMAIN/g" $@
    sed -i "s/<addomain>/$ADDOMAIN/g" $@
    sed -i "s/<hostname>/$HOSTNAME/g" $@
    sed -i "s/<dockernetmask>/$DOCKERNETMASK\/$DOCKERNETMASKLEN/g" $@
    sed -i "s/<netmask>/$NETMASK\/$NETMASKLEN/g" $@
    sed -i "s@<cacert>@$CACERT@g" $@
    sed -i "s@<publiccert>@$PUBLICCERT@g" $@
    sed -i "s@<privatekey>@$PRIVATEKEY@g" $@
    sed -i "s@<domaincontroller>@$HOSTNAME.$DOMAIN@g" $@
    sed -i "s@<secret>@$ADPASSWORD@g" $@
}

appSetup () {
    echo "[INFO] setup"

# TLS Settings
    generateCertificate

    addgroup --system --gid 5000 vmail
    adduser --system --home /srv/vmail --uid 5000 --gid 5000 --disabled-password --disabled-login vmail
#    chgrp vmail /var/mail
#    chmod 777 /var/mail

    ln -s /etc/dovecot/dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap-userdb.conf.ext

    updatefile /etc/dovecot/dovecot-ldap.conf.ext

    touch /etc/dovecot/.alreadysetup

    # To make logrotate work (rsyslogd has to reopen logs
    mv /usr/sbin/policy-rc.d /usr/sbin/policy-rc.d.saved
    sed -i "s@#mail_max_userip_connections = 10@mail_max_userip_connections = 30@" /etc/dovecot/conf.d/20-imap.conf

    # Remove last lines from /etc/rsyslogd.conf to avoid errors in '/var/log/messages' such as
    # "rsyslogd-2007: action 'action 17' suspended, next retry is"
    sed -i '/# The named pipe \/dev\/xconsole/,$d' /etc/rsyslog.conf
}

appStart () {
    [ -f /etc/dovecot/.alreadysetup ] && echo "Skipping setup..." || appSetup

    service cron start
    # Start the services
    /usr/bin/supervisord
}

appHelp () {
	echo "Available options:"
	echo " app:start          - Starts all services needed for mail server"
	echo " app:setup          - First time setup."
	echo " app:help           - Displays the help"
	echo " [command]          - Execute the specified linux command eg. /bin/bash."
}

case "$1" in
	app:start)
		appStart
		;;
	app:setup)
		appSetup
		;;
	app:help)
		appHelp
		;;
	*)
		if [ -x $1 ]; then
			$1
		else
			prog=$(which $1)
			if [ -n "${prog}" ] ; then
				shift 1
				$prog $@
			else
				appHelp
			fi
		fi
		;;
esac

exit 0
