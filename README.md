# mailserver
Mailserver running postfix, fetchmail and dovecot

## Initial setup
Modify the environment variables in the docker-compose.yml. 

Create a postfix user with a password in the group 'Services'
Use the password in the docker-compose.yml:

` - ADPASSWORD=<password for postfix to access AD>`

Issue the build command:

` docker-compose build`

To start and stop the containers:

` docker-compose up -d`
` docker-compose stop`
