#!/bin/bash

#set -e

HOSTNAME=$(hostname)
CERTFOLDER=/etc/postfix/certs
CACERT=${CERTFOLDER}/ssl-cert-snakeoil.pem
PRIVATEKEY=${CERTFOLDER}/mail.key
PUBLICCERT=${CERTFOLDER}/mailcert.pem
#PRIVATEKEY=/certificates/privkey.pem
#PUBLICCERT=/certificates/fullchain.pem

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

    chown -R root:root ${CERTFOLDER}
    chmod -R 600 ${CERTFOLDER}
}

updatefile() {
    sed -i "s/<domain>/$DOMAIN/g" $@
    sed -i "s/<emaildomain>/$EMAILDOMAIN/g" $@
    if [ ! -z $ADDOMAIN ]; then
        sed -i "s/<addomain>/$ADDOMAIN/g" $@
        sed -i "s@<secret>@$ADPASSWORD@g" $@
    fi
    sed -i "s/<hostname>/$HOSTNAME/g" $@
    sed -i "s/<dockernetmask>/$DOCKERNETMASK\/$DOCKERNETMASKLEN/g" $@
    sed -i "s/<netmask>/$NETMASK\/$NETMASKLEN/g" $@
    sed -i "s@<cacert>@$CACERT@g" $@
    sed -i "s@<publiccert>@$PUBLICCERT@g" $@
    sed -i "s@<privatekey>@$PRIVATEKEY@g" $@
    sed -i "s@<domaincontroller>@$ADCONTROLLER@g" $@
}

appSetup () {
    echo "[INFO] setup"

    mkdir -p ${CERTFOLDER}

# copy files to chroot environment otherwise dns-resolve does not work
    cp /etc/services /var/spool/postfix/etc/
    cp /etc/resolv.conf /var/spool/postfix/etc/

    cd /etc/postfix/

    if [ -z $ADCONTROLLER ] ; then
        ADCONTROLLER=$HOSTNAME.$DOMAIN
    fi

    updatefile main.cf
    updatefile ldap_virtual_aliases.cf
    updatefile ldap_virtual_recipients.cf
    updatefile virtual_domains
    updatefile virtual_recipients.cf

#   configure relay

    postconf -e maillog_file=/dev/stdout
    postconf -e relayhost=[${RELAYHOST}]:587
    echo [${RELAYHOST}]:587 ${RELAYUSER}:${RELAYUSERPASSWORD} >> /etc/postfix/sasl_passwd
    sed -i "s/\"//g" /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd

#   configure sasl authentication

    postconf -e smtp_sasl_auth_enable=yes
    postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
    postconf -e smtp_sasl_security_options=noanonymous
    postconf -e smtpd_tls_security_level=may
    postconf -e virtual_transport=lmtp:inet:dovecot
    postconf -e virtual_mailbox_domains=hash:/etc/postfix/virtual_domains
    if [ "${LDAP_YESNO}" = "y" ]; then
        postconf -e virtual_mailbox_maps=proxy:ldap:/etc/postfix/ldap_virtual_recipients.cf
        postconf -e virtual_alias_maps=proxy:ldap:/etc/postfix/ldap_virtual_aliases.cf
    else
        postconf -e virtual_mailbox_maps=hash:/etc/postfix/virtual_recipients.cf
	postmap /etc/postfix/virtual_recipients.cf
    fi

#   configure certificates (Letsencrypt) or generate self-signed cert

    ls -als  /certificates/fullchain.pem
    if [ -f /certificates/fullchain.pem ]; then
        echo "Letsencrypt certificates present"
	postconf -e smtpd_tls_cert_file=/certificates/fullchain.pem
        postconf -e smtpd_tls_key_file=/certificates/privkey.pem
    else
        echo "Letsencrypt certificates MISSING, generate self-signed certs"
        generateCertificate
    fi

#   miscelaneous

    postconf -e mydestination=\$myhostname,localhost,localhost.\$mydomain
    postconf -e message_size_limit=20480000
    postconf -e disable_vrfy_command=yes

#    sed -i "s/START=no/START=yes/g" /etc/default/saslauthd
#    sed -i "s/MECHANISMS=.*/MECHANISMS=\"ldap\"/g" /etc/default/saslauthd

    postmap hash:/etc/postfix/virtual_domains
    postconf compatibility_level=2

    touch /etc/postfix/.alreadysetup

}

appStart () {
    [ -f /etc/postfix/.alreadysetup ] && echo "Skipping setup..." || appSetup

    trap "appStop SIGINT" SIGINT
    trap "appStop SIGTERM" SIGTERM
    /usr/sbin/postfix start-fg &
    wait $!
    echo "Process stopped"
}

appStop () {
    echo "Signal $1 caught"
    /usr/sbin/postfix stop
    echo "Postfix stop command complete"
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
