#!/bin/bash

set -e

CERTFOLDER=/etc/postfix/certs
CACERT=${CERTFOLDER}/ssl-cert-snakeoil.pem
PRIVATEKEY=${CERTFOLDER}/mail.key
PUBLICCERT=${CERTFOLDER}/mailcert.pem

info () {
    echo "[INFO] $@"
}

generateCertificate() {
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -subj "${CERTIFICATESUBJECT}" \
	-keyout ${PRIVATEKEY} -out ${PUBLICCERT}

    cp /etc/ssl/certs/ssl-cert-snakeoil.pem ${CACERT}
    openssl dhparam -2 -out ${CERTFOLDER}/dh_512.pem 512
    openssl dhparam -2 -out ${CERTFOLDER}/dh_1024.pem 1024    

    chown -R root:root /etc/postfix/certs/
    chmod -R 600 /etc/postfix/certs/
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

    chmod +x /postfix.sh

    mkdir ${CERTFOLDER}
    generateCertificate

    cd /etc/postfix/

    updatefile main.cf
    updatefile ldap_virtual_aliases.cf
    updatefile ldap_virtual_recipients.cf
    updatefile virtual_domains
    updatefile drop.cidr

#   configure relay

    postconf -e relayhost=[${RELAYHOST}]:587
    postconf -e smtp_sasl_auth_enable=yes
    postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
    postconf -e smtp_sasl_security_options=noanonymous
    postconf -e smtpd_tls_security_level=may

    echo [${RELAYHOST}]:587 ${RELAYUSER}:${RELAYUSERPASSWORD} >> /etc/postfix/sasl_passwd
    sed -i "s/\"//g" /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd

#    sed -i "s/START=no/START=yes/g" /etc/default/saslauthd
#    sed -i "s/MECHANISMS=.*/MECHANISMS=\"ldap\"/g" /etc/default/saslauthd

    postmap hash:/etc/postfix/virtual_domains
    postconf compatibility_level=2

    touch /etc/postfix/.alreadysetup

}

appStart () {
    [ -f /etc/postfix/.alreadysetup ] && echo "Skipping setup..." || appSetup

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
