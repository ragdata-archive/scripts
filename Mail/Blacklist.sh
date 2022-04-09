#!/bin/bash

echo "What domain are we blacklisting: "
IFS= read -r domain
echo "blacklist_from *@$domain" >> /etc/spamassassin/local.cf
sudo systemctl restart spamassassin
