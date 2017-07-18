#!/usr/local/bin/perl

$vnid = 0;
while (my $line = <>) {
	if ($line =~ /Virtual Switching Node (\d+\.\d+\.\d+\.\d+)/) {
		$vnid = $1;
		$get_topo = 1;
	}
	if ($get_topo) {
		if ($line =~ /^Topo\s+:\s+0x\d+\s+\(\s+(.*)\)/) {
			$VSN{$vnid} = $1;
			print "$vnid = $1\n";
			$get_topo = 0;
		}
	}
	if ($line =~ /3 Hop.s.:\[(\d+\.\d+\.\d+\.\d+)\]\.\d+\s+\[(\d+\.\d+\.\d+\.\d+)\]\.\d+\s+\[(\d+\.\d+\.\d+\.\d+)\]\.\d+/) {
		my @hops = ($1,$2,$3);
		chomp($line);
		printf("$line %s:%s:%s\n", $VSN{$hops[0]}, $VSN{$hops[1]}, $VSN{$hops[2]});
	}
}
