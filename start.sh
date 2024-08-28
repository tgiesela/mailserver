#!/bin/bash
# When using this file, it is assumed that the vpn service is not used.
# We will remove the depends_on line in a temporary docker-compose.yml

sed 's/depends_on: \[vpn[,]\{0,1\}/depends_on: \[/g' docker-compose.yml > docker-compose.tmp.yml
source vars
docker compose -f docker-compose.tmp.yml up --build -d
rm docker-compose.tmp.yml
