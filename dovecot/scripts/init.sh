#!/bin/bash

set -e
HOSTNAME=$(hostname)
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
    sed -i "s@<domaincontroller>@$ADCONTROLLER@g" $@
    sed -i "s@<secret>@$ADPASSWORD@g" $@
}

appSetup () {
    echo "[INFO] setup"

# TLS Settings
#    generateCertificate

    addgroup --system --gid 5000 vmail
    adduser --system --home /home/vmail --uid 5000 --gid 5000 --disabled-password --disabled-login vmail
    chown dovecot:dovecot /var/mail
    chmod g+x /var/mail

    if [ "${LDAP_YESNO}" = 'y' ] ; then
        mv /etc/dovecot/conf.d/ldap/* /etc/dovecot/conf.d/
        mv /etc/dovecot/conf.d/dovecot-ldap.conf.ext /etc/dovecot/
        ln -s /etc/dovecot/dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap-userdb.conf.ext
        updatefile /etc/dovecot/dovecot-ldap.conf.ext
    else
	useradd -m -p $(openssl passwd -1 ${MAILPASSWORD}) ${MAILUSER}
    fi

    touch /etc/dovecot/.alreadysetup

    sed -i "s@#mail_max_userip_connections = 10@mail_max_userip_connections = 30@" /etc/dovecot/conf.d/20-imap.conf

    cat << EOF >> /etc/dovecot/conf.d/10-master.conf
service auth {
    inet_listener {
    address =
    haproxy = no
    port = 12345
    reuse_port = no
    ssl = no
  }
}
service lmtp {
  inet_listener lmtp {
    port = 24
  }
}
EOF
    cat << EOF >> /etc/dovecot/conf.d/10-auth.conf
auth_username_format = %Ln
EOF

}

appStart () {
    [ -f /etc/dovecot/.alreadysetup ] && echo "Skipping setup..." || appSetup

    trap "appStop" SIGTERM
    trap "appStop" SIGINT
    set +e
    exec /usr/sbin/dovecot -F &
    wait $!
    echo "Wait completed"
}
appStop () {
    echo "TRAP HANDLER" active
    echo "Stopping"
    /usr/sbin/dovecot stop
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
echo "Exiting now"
exit 0
