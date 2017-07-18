#!/usr/local/bin/perl

#    00:34.856_931_200   7.962   0   SOFi3   04  FC4UData; Type = (0xFF) Vendor Specific;    2080    201700  610600  0000    0000    8008        380000  00000000        1C76F533    (Correct)   EOFt(+)
#    00:34.856_940_988   9.788   0   LRR         4
#    00:34.856_941_384   0.396   0   SOFi3   04  FC4UData; Type = (0xFF) Vendor Specific;    2080    201700  610600  0000    0000    8009        380000  00000000        4886FDCF    (Correct)   EOFt(+)
#    00:34.856_942_682   19.106  1   R-Rdy           4


while(chomp($line = <>)) {
	($bm, $line) = split(/\t/,$line,2);
	my @s = split(/\t/,$line);
	my $port = $s[2];
	my $prim = $s[3];

	$Events{$port}++ unless $bm =~ /Bookmark/;

	if ($prim =~ /R-Rdy|SOF|LR/) {
		$tot_RRDY{$port}++ if $prim =~ /R-Rdy/;
		$tot_SOF{$port}++  if $prim =~ /SOF/;

		$credit{$port}++ if $prim =~ /R-Rdy/;
		my $other = get_other_port($port);

		if ($prim =~ /SOF/) {
			if ($other == 0) {
				$sub_from_other{$port}++;
			} else {
				if ($sub_from_other{$port}) {
					$credit{$other} -= $sub_from_other{$port};
					$sub_from_other{$port} = 0;
				}
			}
			$credit{$other}--;
		}


		foreach my $evp (sort keys %Events) {
			print_ports_sof_rrdy($evp);
		}
		printf " : %s\n", substr($line, 0, 50);
	}
	print_stats() if $prim =~ /LR/;
} 

foreach my $evp (keys %Events) {
	print "$evp : $Events{$evp}\n";

}

sub print_ports_sof_rrdy() {
	my $port = shift;
	printf "[%s:RRDY=%5d SOF=%5d:Cr=%-3d] ", $port, $tot_RRDY{$port}, $tot_SOF{$port}, $credit{$port};
}

sub get_other_port() {
	my $port = shift;
	my $other = 0;

	foreach my $evp (keys %Events) {
		next if $evp eq $port;
		$other = $evp;
	}
	return $other;
}

sub print_stats() {
	foreach my $port (sort {$a <=> $b} keys (%tot_RRDY)) {
		printf "[%s] RRDY=%10d SOF=%10d credit=%d\n", $port, $tot_RRDY{$port}, $tot_SOF{$port}, $credit{$port};
	}
}
