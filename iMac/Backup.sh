#!/bin/bash

SSHDestUser="imac-backup@real.chse.dev"
BasePath="/media/easystore/iMacBackup"

/usr/bin/rsync -e 'ssh -p 1000' -avzp /Users/Hall/Desktop/* $SSHDestUser:$BasePath/Desktop/
/usr/bin/rsync -e 'ssh -p 1000' -avzp /Users/Hall/Documents/* $SSHDestUser:$BasePath/Documents/
/usr/bin/rsync -e 'ssh -p 1000' -avzp /Users/Hall/Pictures/* $SSHDestUser:$BasePath/Pictures/
#/usr/bin/rsync -e 'ssh -p 1000' -avzp /Users/Hall/Music/* $SSHDestUser:$BasePath/Music/
/usr/bin/rsync -e 'ssh -p 1000' -avzp /Users/Hall/Movies/* $SSHDestUser:$BasePath/Movies/

/usr/bin/pmset sleepnow # Put Mac back to sleep. (System Prefs wakes it a minute before script fires from cronjob.)

exit
