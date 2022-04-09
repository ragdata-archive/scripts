#!/bin/bash

SSHDestUser="imac-backup@real.chse.dev"
BasePath="/media/easystore/iMacBackup"

rsync -e 'ssh -p 1000' -avzp /Users/Hall/Desktop/* $SSHDestUser:$BasePath/Desktop/
rsync -e 'ssh -p 1000' -avzp /Users/Hall/Documents/* $SSHDestUser:$BasePath/Documents/
rsync -e 'ssh -p 1000' -avzp /Users/Hall/Pictures/* $SSHDestUser:$BasePath/Pictures/
rsync -e 'ssh -p 1000' -avzp /Users/Hall/Music/* $SSHDestUser:$BasePath/Music/
rsync -e 'ssh -p 1000' -avzp /Users/Hall/Movies/* $SSHDestUser:$BasePath/Movies/

pmset sleepnow # Put Mac back to sleep. (System Prefs wakes it a minute before script fires from cronjob.)

exit
