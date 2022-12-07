#!/bin/bash

DestFolder_WWW="/root/backups/ms/www"
DestFolder_WWW_var="/root/backups/ms/www/var-www"
DestFolder_WWW_apache2="/root/backups/ms/www/etc-apache2"
DestFolder_WWW_letsencrypt="/root/backups/ms/www/etc-letsencrypt"
DestFolder_Docker="/root/backups/ms/docker"
DestFolder_RootHomeFolder="/root/backups/ms/root-home"
DestFolder_GHCLI="/root/backups/ms/github-ci-runner"
DB_PW=$(<~/DB_PW.txt)
DestSSHInfo="root@real.chse.dev"

# Main Server
## MySQL
mysqldump --all-databases --single-transaction --quick --lock-tables=false -u root -p"$DB_PW" > /tmp/sql-dump.sql
rsync -e 'ssh -p 1010' -az /tmp/sql-dump.sql $DestSSHInfo:$DestFolder_WWW/WWW-SQL-Dump.sql
rm /tmp/sql-dump.sql
## /var/www, /etc/apache2, /etc/letsencrypt
rsync -e 'ssh -p 1010' -azrd --delete /var/www/* $DestSSHInfo:$DestFolder_WWW_var/
rsync -e 'ssh -p 1010' -azrd --delete /etc/apache2/* $DestSSHInfo:$DestFolder_WWW_apache2/
rsync -e 'ssh -p 1010' -azrd --delete /etc/letsencrypt/* $DestSSHInfo:$DestFolder_WWW_letsencrypt/
## /dockerData
rsync -e 'ssh -p 1010' -azrd --delete /dockerData/* $DestSSHInfo:$DestFolder_Docker/
## /root
rsync -e 'ssh -p 1010' -az /root/* $DestSSHInfo:$DestFolder_RootHomeFolder/
## /home/github-ci-runner
rsync -e 'ssh -p 1010' -azrd --delete /home/github-ci-runner/* $DestSSHInfo:$DestFolder_GHCLI/
