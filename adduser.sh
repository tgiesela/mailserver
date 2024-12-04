#! /bin/bash

echo This script will add a user to a dovecot instance without LDAP/AD.
read -rp "Enter username: " username
read -s -rp "Password: " password
docker exec -it dovecot useradd -m -p "$(openssl passwd -1 "\"${password}"\")" "${username}"
