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
/usr/bin/mysqldump --all-databases --single-transaction --quick --lock-tables=false -u root -p"$DB_PW" > /tmp/sql-dump.sql
/usr/bin/rsync -e 'ssh -p 1010' -az /tmp/sql-dump.sql $DestSSHInfo:$DestFolder_WWW/WWW-SQL-Dump.sql
/usr/bin/rm /tmp/sql-dump.sql
## /var/www, /etc/apache2, /etc/letsencrypt
/usr/bin/rsync -e 'ssh -p 1010' -azrd --delete /var/www/* $DestSSHInfo:$DestFolder_WWW_var/
/usr/bin/rsync -e 'ssh -p 1010' -azrd --delete /etc/apache2/* $DestSSHInfo:$DestFolder_WWW_apache2/
/usr/bin/rsync -e 'ssh -p 1010' -azrd --delete /etc/letsencrypt/* $DestSSHInfo:$DestFolder_WWW_letsencrypt/
## /dockerData
/usr/bin/rsync -e 'ssh -p 1010' -azrd --delete /dockerData/* $DestSSHInfo:$DestFolder_Docker/
## /root
/usr/bin/rsync -e 'ssh -p 1010' -azrd --delete /root/* $DestSSHInfo:$DestFolder_RootHomeFolder/
## /home/github-ci-runner
/usr/bin/rsync -e 'ssh -p 1010' -azrd --delete /home/github-ci-runner/* $DestSSHInfo:$DestFolder_GHCLI/
