#!/bin/sh
cd ~/zgo; 
DATECMD="date +%Y%m%d-%H%M%S"
tar -zcvf backup/$($DATECMD).db.tar.gz zi.db
tar -zcvf backup/$($DATECMD).8081.nohup.out.tar.gz 8081.nohup.out
rm 8081.nohup.out
perl restart.pl 8081
