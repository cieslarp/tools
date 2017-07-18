#!/usr/local/bin/perl

push (@IPs, @ARGV);

@IPs = ("10.38.33.42", "10.38.33.43") unless scalar @IPs;

while (1) {
    for my $ip (@IPs) {
        my $dmesg = `switchssh $ip "/bin/dmesg -c"`;
        if (length($dmesg) > 3) {
            print "=" x 10 . "[$ip] " . "=" x 10 . " " . `date`;
            print $dmesg;
            $once{$ip} = 0;
        } else {
            print "=" x 10 . "[$ip] " . "=" x 10 . " " . `date` unless $once{$ip};
            $once{$ip} = 1;
        }
        sleep ++$once{$ip} if $dmesg =~ /Connection refused/;
    }
}
