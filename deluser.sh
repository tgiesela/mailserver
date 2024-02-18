# ! /bin/bash
echo This script will delete a user from a dovecot instance without LDAP/AD.
read -p "Enter username: " username
docker exec -it dovecot userdel ${username}
