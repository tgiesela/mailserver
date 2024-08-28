#!/bin/bash
DEFAULT_DATAFOLDER=/folder/to/store/docker/config
DEFAULT_MAILUSER=dovecotuser
DEFAULT_MAILUSERPASSWORD=dovecotuser
INETDEV=$(ip route get 8.8.8.8 | grep -oP 'dev \K[^ ]+')
INETADDR=$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')
DEFAULT_IP_ADDRESS=${INETADDR}
DEFAULT_EMAILDOMAIN=example.local
DEFAULT_LDAP_YESNO=n

read -p "Domain name (${DEFAULT_EMAILDOMAIN})" EMAILDOMAIN
if [ -z ${EMAILDOMAIN} ]; then
    EMAILDOMAIN=${DEFAULT_EMAILDOMAIN}
fi
IFS="." read -a DCPARTS <<<$EMAILDOMAIN
ADDOMAIN=dc=${DCPARTS[0]}
for part in ${DCPARTS[@]:1}; do
    ADDOMAIN=$ADDOMAIN,dc=$part
done

read -p "Use LDAP/AD authentication (y/n) (${DEFAULT_LDAP_YESNO}): " LDAP_YESNO
if [ -z ${LDAP_YESNO} ]; then
    LDAP_YESNO=${DEFAULT_LDAP_YESNO}
fi
case $LDAP_YESNO in
    n|no|N|NO)
		 read -p "Enter first mailuser name (${DEFAULT_MAILUSER}): " MAILUSER
		 if [ -z $MAILUSER ]; then
		    MAILUSER=${DEFAULT_MAILUSER}
 		    MAILUSERPASSWORD=${DEFAULT_MAILUSERPASSWORD}
                    echo "First mailuser name set to ${MAILUSER} with password $MAILUSERPASSWORD"
		 else
  		    read -p "Enter first mailuser password (${DEFAULT_MAILUSERPASSWORD}): " MAILUSERPASSWORD
		 fi
                 ;;
    y|yes|Y|YES) 
		 ADCONTROLLER=$(nslookup -type=SRV  _ldap._tcp.dc._msdcs.${EMAILDOMAIN} | grep '_ldap'| awk '{split($0,parts," "); print parts[7]}')
		 if [ -z $ADCONTROLLER ]; then
		     ADCONTROLLER=$(nslookup -type=SRV  _ldap._tcp.dc._msdcs.${EMAILDOMAIN} 127.0.0.1 | grep '_ldap'| awk '{split($0,parts," "); print parts[7]}')
		     if [ -z $ADCONTROLLER ]; then
                         echo "Cannot obtain the name of the domaincontroller. Make sure the DNS server for the domain is reachable."
                         exit
                     fi
                 fi
		 ADCONTROLLER=$(echo "$ADCONTROLLER" | sed 's/\.$//')
		;;

    *) echo "Invalid response"
       exit ;;
esac

read -p "Name of folder to store persistent data (${DEFAULT_DATAFOLDER}): " DATAFOLDER
if [ -z $DATAFOLDER ]; then
    DATAFOLDER=${DEFAULT_DATAFOLDER}
fi

echo '# settings mailserver' > vars
echo export DATAFOLDER=${DATAFOLDER} >> vars
echo export ADCONTROLLER=${ADCONTROLLER} >> vars
echo export ADDOMAIN=${ADDOMAIN} >> vars
echo export MAILUSERPASSWORD=${MAILUSERPASSWORD} >> vars
echo export EXTERNALEMAILDOMAIN=your.external.domain >> vars
# Update following as required
COUNTRY=NL
PROVINCE=N-H
CITY=Amsterdam
ORG=Organization
echo export CERTIFICATESUBJECT=/C=${COUNTRY}/ST=${PROVINCE}/L=${CITY}/O=${ORG}/CN=${EXTERNALEMAILDOMAIN} >> vars
echo export EMAILDOMAIN=${EMAILDOMAIN} >> vars
echo export MAILUSER=${MAILUSER} >> vars
echo export LDAP_YESNO=${LDAP_YESNO} >> vars
echo export RELAYHOST='<relay host, e.g. smtp.gmail.com>' >> vars
echo export RELAYUSER='<email at relay host>' >> vars
echo export RELAYUSERPASSWORD='<password for email at relay host>' >> vars
echo export LOCALNETWORK='192.168.1.0' >> vars
echo export LOCALNETWORKMASKLEN=24  >> vars
echo export ADPASSWORD='<password for aduser>' >> vars
echo export LOCALNETWORK='<docker network in form ip/len or ${DOCKERNETWORK} if using vpn>' >> vars
echo export DOCKERNETWORKIP='<docker network ip part or ${DOCKERNETWORKIP} if using vpn>' >> vars
echo export DOCKERNETWORKMASKLEN='<docker network ipmask-len or ${DOCKERNETWORKMASKLEN} if using vpn>' >> vars
echo export LOCALDNS='<ip of local dns server>' >> vars
echo export MAILFOLDER='<folder to store email>' >> vars
echo -e "\nPlease update the generated 'vars' file\n"
