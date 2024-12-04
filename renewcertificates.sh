#!/bin/bash

# To get the first certificate: 
#	certbot certonly -d ${EXTERNALEMAILDOMAIN}
CURRFOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$CURRFOLDER"/vars
CERTFOLDER=/etc/letsencrypt/live/${EXTERNALEMAILDOMAIN}
TARGETFOLDER=${DATAFOLDER}/certificates
ORIGDATE=$(stat -L -c %Y "$TARGETFOLDER"/cert.pem)
certbot --standalone certonly -n -d "${EXTERNALEMAILDOMAIN}"
NEWDATE=$(stat -L -c %Y "${CERTFOLDER}"/cert.pem)

echo "New date=" "${NEWDATE}"",Original date=""${ORIGDATE}"

if [ "${NEWDATE}" == "${ORIGDATE}" ]; then
     echo "Certificate not renewed"
else
     echo "Certificate has changed"
     echo "Installing the new certificate"
     cp -p "${CERTFOLDER}"/*.pem "$TARGETFOLDER"/
     docker exec dovecot doveadm reload
fi
