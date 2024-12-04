#!/bin/bash
DEFAULT_DATAFOLDER=/folder/to/store/docker/config
DEFAULT_MAILUSER=dovecotuser
DEFAULT_MAILUSERPASSWORD=dovecotuser
DEFAULT_EMAILDOMAIN=example.local
DEFAULT_LDAP_YESNO=n

read -rp "Domain name (${DEFAULT_EMAILDOMAIN})" EMAILDOMAIN
if [ -z "${EMAILDOMAIN}" ]; then
    EMAILDOMAIN=${DEFAULT_EMAILDOMAIN}
fi
IFS="." read -ra DCPARTS <<<"$EMAILDOMAIN"
ADDOMAIN=dc=${DCPARTS[0]}
for part in "${DCPARTS[@]:1}"; do
    ADDOMAIN=$ADDOMAIN,dc=$part
done

read -rp "Use LDAP/AD authentication (y/n) (${DEFAULT_LDAP_YESNO}): " LDAP_YESNO
if [ -z "${LDAP_YESNO}" ]; then
    LDAP_YESNO=${DEFAULT_LDAP_YESNO}
fi
case $LDAP_YESNO in
    n|no|N|NO)
		 read -rp "Enter first mailuser name (${DEFAULT_MAILUSER}): " MAILUSER
		 if [ -z "$MAILUSER" ]; then
		    MAILUSER=${DEFAULT_MAILUSER}
 		    MAILUSERPASSWORD=${DEFAULT_MAILUSERPASSWORD}
                    echo "First mailuser name set to ${MAILUSER} with password $MAILUSERPASSWORD"
		 else
  		    read -rp "Enter first mailuser password (${DEFAULT_MAILUSERPASSWORD}): " MAILUSERPASSWORD
		 fi
                 ;;
    y|yes|Y|YES) 
		 ADCONTROLLER=$(nslookup -type=SRV  _ldap._tcp.dc._msdcs."${EMAILDOMAIN}" | grep '_ldap'| awk '{split($0,parts," "); print parts[7]}')
		 if [ -z "$ADCONTROLLER" ]; then
		     ADCONTROLLER=$(nslookup -type=SRV  _ldap._tcp.dc._msdcs."${EMAILDOMAIN}" 127.0.0.1 | grep '_ldap'| awk '{split($0,parts," "); print parts[7]}')
		     if [ -z "$ADCONTROLLER" ]; then
                         echo "Cannot obtain the name of the domaincontroller. Make sure the DNS server for the domain is reachable."
                         exit
                     fi
                 fi
		 ADCONTROLLER=$(echo "$ADCONTROLLER" | sed 's/\.$//')
		;;

    *) echo "Invalid response"
       exit ;;
esac

read -rp "Name of folder to store persistent data (${DEFAULT_DATAFOLDER}): " DATAFOLDER
if [ -z "$DATAFOLDER" ]; then
    DATAFOLDER=${DEFAULT_DATAFOLDER}
fi

{   echo '#!/bin/bash' ; 
    echo '# settings mailserver' ;
    echo export DATAFOLDER="${DATAFOLDER}" ;
    echo export ADCONTROLLER="${ADCONTROLLER}" ;
    echo export ADDOMAIN="${ADDOMAIN}" ;
    echo export MAILUSERPASSWORD="${MAILUSERPASSWORD}" ;
    echo export EXTERNALEMAILDOMAIN=your.external.domain 
} > vars

# Update following as required
COUNTRY=NL
PROVINCE=N-H
CITY=Amsterdam
ORG=Organization
{
    echo export CERTIFICATESUBJECT=/C=${COUNTRY}/ST=${PROVINCE}/L=${CITY}/O=${ORG}/CN="${EXTERNALEMAILDOMAIN}" ;
    echo export EMAILDOMAIN="${EMAILDOMAIN}" ;
    echo export MAILUSER="${MAILUSER}" ;
    echo export LDAP_YESNO="${LDAP_YESNO}" ;
    echo export RELAYHOST='<relay host, e.g. smtp.gmail.com>' ;
    echo export RELAYUSER='<email at relay host>' ;
    echo export RELAYUSERPASSWORD='<password for email at relay host>' ;
    echo export LOCALNETWORK='192.168.1.0' ;
    echo export LOCALNETWORKMASKLEN=24  ;
    echo export ADPASSWORD='<password for aduser>' ;
    echo export LOCALNETWORK="<docker network in form ip/len or \${DOCKERNETWORK} if using vpn>" ;
    echo export DOCKERNETWORKIP="<docker network ip part or \${DOCKERNETWORKIP} if using vpn>" ;
    echo export DOCKERNETWORKMASKLEN="<docker network ipmask-len or \${DOCKERNETWORKMASKLEN} if using vpn>" ;
    echo export LOCALDNS='<ip of local dns server>' ;
    echo export MAILFOLDER='<folder to store email>' ;
} >> vars

echo -e "\nPlease update the generated 'vars' file\n"
