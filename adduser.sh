# ! /bin/bash

echo This script will add a user to a dovecot instance without LDAP/AD.
read -p "Enter username: " username
read -s -p "Password: " password
docker exec -it dovecot useradd -m -p $(openssl passwd -1 ${password}) ${username}
