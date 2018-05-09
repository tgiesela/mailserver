#!/bin/bash

set -e

info () {
    echo "[INFO] $@"
}

appSetup () {
    echo "[INFO] setup"

    chmod 700 /etc/fetchmailrc
    touch /var/log/fetchmail.log

#    touch /etc/fetchmail/.alreadysetup

    # Remove last lines from /etc/rsyslogd.conf to avoid errors in '/var/log/messages' such as
    # "rsyslogd-2007: action 'action 17' suspended, next retry is"
    sed -i '/# The named pipe \/dev\/xconsole/,$d' /etc/rsyslog.conf

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
