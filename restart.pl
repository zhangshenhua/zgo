#!/bin/perl -w
#usage: ./restart.pl 8088

use 5.010;

$PORT = $ARGV[0];

$PID = `  lsof -t -i:"$PORT"  `;

print $PID;

if($PID) {
        say `kill $PID `;
}



$cmd = qq{
nohup ./zgo -dbfile zi.db -port $PORT > $PORT.nohup.out &
};

say $cmd;

system $cmd || exit;


say 'OK';
exit;
