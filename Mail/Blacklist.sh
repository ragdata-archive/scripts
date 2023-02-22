#!/bin/bash

echo "What domain are we blacklisting: "
IFS= read -r domain
echo "blacklist_from *@$domain" >> /etc/spamassassin/local.cf
/usr/bin/sudo /usr/bin/systemctl restart spamassassin
