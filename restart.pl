#!/bin/perl -w
#usage: ./restart.pl 8088

use 5.010;

$PORT = $ARGV[0];

$PID = `  lsof -t -i:"$PORT" | xargs echo -n`;

print $PID;


$cmd = qq{
kill $PID && nohup ./zgo -dbfile zi.db -port $PORT > $PORT.nohup.out &
};

say $cmd;

system $cmd || exit;


say 'OK';
exit;
