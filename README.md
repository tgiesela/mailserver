# mailserver
Mailserver running postfix, fetchmail and dovecot

## Initial setup
Modify the environment variables in the docker-compose.yml. 

To be able to use Active Directory accounts, create a user 'postfix' with 
a password in the group 'Services' in Active Directory. Use the password 
in the docker-compose.yml:

` - ADPASSWORD=<password for postfix to access AD>`

Populate the fetchmail/config/fetchmailrc file in the config folder with the accounts 
you want to use to retrieve mail from.

Also change the network addresses in the .yml file. The 10.x.x.x range is your
own local domain, the 172.18.x.x is the docker domain in created docker network.

Issue the build command:

` docker-compose build`

To start and stop the containers:

` docker-compose up -d`

` docker-compose stop`

For fetchmail you need to create a fetchmailrc and .netrc file. See the examples.
If you have access to git secret with a known email-address you can use `git secret reveal` to
get the stored files.
 
