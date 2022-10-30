#!/bin/perl -w
#usage: ./restart.pl 8088

use 5.010;

$PORT = $ARGV[0] || die "port must spec";

$PID = `lsof -t -i:"$PORT" | xargs echo -n`;

say $PID;
chomp $PID;
if($PID) {
    $cmd = qq{
    kill $PID && nohup ./zgo -port $PORT >> $PORT.nohup.out &
    };
}else{
    $cmd = qq{
    nohup ./zgo -port $PORT >> $PORT.nohup.out &
    };
}


say $cmd;

system($cmd) && die "end with error";


say 'OK';

