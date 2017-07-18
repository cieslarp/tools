#!/usr/local/bin/perl

while (my $line = <>) {
	if ($line =~ /FSPF_TE_HEX_DUMP\s/) {
		$line = <> unless ($line =~ /HD:/);
		print $line;
		@s = split(/\s+w/,$line);
		foreach my $w (@s) {
			if ($w =~ /^\d/) {
				my $run = "~sbusch/bin/bmWordDecode $w";
				print $run . "\n";
				my $out = `$run`;
				foreach my $port (split(/\s+/,$out)) {
					if ($port =~ /^\d+$/) {
						$OnlinePorts{$port}++;
					}
				}
			}
		}
	}
}

$num_ports = 0;
print "\n";
foreach my $p (sort {$a <=> $b} keys %OnlinePorts) {
	$num_ports++;
	printf "%4d ", $p;
	if (($num_ports % 16) == 0) { print "\n"; }
}
print "\nRouteablePorts:$num_ports\n";
