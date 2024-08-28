#/bin/bash
# When using this file, it is assumed that the vpn service is not used.
# We will remove the depends_on line in a temporary docker-compose.yml

sed 's/depends_on: \[vpn[,]\{0,1\}/depends_on: \[/g' docker-compose.yml > docker-compose.tmp.yml
CMD=$1
if [ -z "$CMD" ] ; then
    echo "No option specified, assuming STOP"
    CMD=stop
fi
source vars
docker compose -f docker-compose.tmp.yml $CMD
rm docker-compose.tmp.yml
