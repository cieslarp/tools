#!/usr/local/bin/perl

$ip = shift;
$port = shift;
die "$0 <ip address> <port>\n" unless $port;

while(1) {
    $count++;
    $ret = `expect ~/bin/cfe.exp $ip $port`;
    print "$count\n" unless ($count%1000);
    if ($ret =~ /CFE/) {
        print $ret;
        exit;
    }
}
