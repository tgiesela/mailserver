#!/bin/bash

set -e

info () {
    echo "[INFO] $@"
}

appSetup () {
    echo "[INFO] setup"

    chmod 0700 /etc/fetchmailrc
    chmod 0700 ~/.netrc

}

appStart () {
     appSetup
     /usr/bin/fetchmail -v -N -f /etc/fetchmailrc
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
