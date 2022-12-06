#!/bin/bash

DestFolder="/root/backups/miab/"
DestSSHInfo="root@real.chse.dev"

rsync -e 'ssh -p 1010' -azrd --delete /home/user-data/backup/encrypted/* $DestSSHInfo:$DestFolder
