#OID=0x43228006: TXRX RX iu sof:0x171a9860, hdr:0x01531900, 0x00338401,0x007e67fe, pld[0]:0xff6bfe6b, eof: 0x3000000, prcode: 0x37
while (my $line = <>) {
	next if $UNIQ{$line};
	if ($line =~ /TXRX RX iu.*prcode: 0x37/) {
		my @s = split(/:/,$line);
		my @h = split(/,/,$s[3]);
		print "D=$h[0] S=$h[1]\n";
		my $did = hex($h[0]) & 0xffffff;
		$h[1] =~ s/\s+//g;
		my $sid = hex($h[1]) & 0xffffff;
		$DID{$did}++;
		$SID{$sid}++;
		$SID_D{$sid} .= sprintf("%06x,",$did);
		my $pid = sprintf("d:%06x s:%06x", $did, $sid);
		$PID{$pid}++;
		$UNIQ{$line}++;
	}
}

print "DID:\n";
for my $k (sort {$DID{$b} <=> $DID{$a}} keys %DID) {
	printf "%10s = %06x\n", $DID{$k}, $k;
}

print "SID:\n";
for my $k (sort {$SID{$b} <=> $SID{$a}} keys %SID) {
	printf "%10s = %06x : %s\n", $SID{$k}, $k, $SID_D{$k};
}
print "Pairs:\n";
for my $k (sort {$PID{$b} <=> $PID{$a}} keys %PID) {
	printf "%10s = %s\n", $PID{$k}, $k;
}
