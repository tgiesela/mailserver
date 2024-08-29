# mailserver
Mailserver running postfix, fetchmail and dovecot

## Initial setup
Create a `vars` file like `vars.example`. You can do this bij executing `./mail_configure.sh`. Set the variables for your environment. Variables starting with 'AD' are only required when using Active Directory.

To be able to use Active Directory accounts (if applicable), create a user 'postfix' with 
a password in the group 'Services' in Active Directory. Use the password 
in the docker-compose.yml:

` - ADPASSWORD=<password for postfix to access AD>`

Populate the fetchmail/config/fetchmailrc file in the config folder with the accounts 
you want to use to retrieve mail from.

To start and stop the containers:

` ./start.sh`
` ./stop.sh` 
` ./stop.sh down`

For fetchmail you need to create a fetchmailrc and .netrc file. See the examples.
If you have access to git secret with a known email-address you can use `git secret reveal` to
get the stored files.
 
