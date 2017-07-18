#!/usr/local/bin/perl

$snode = 0;
$dnode = 0;

while (my $line = <>) {
	if ($line =~ /^Source Node Audit: \d+\.(\d+)\.\d+\.(\d+)/) {
		$snode = $1 . "." . $2;
	}
	if ($line =~ /^Destination Node Audit: \d+\.(\d+)\.\d+\.(\d+)/) {
		$dnode = $1 . "." . $2;
	}
	if ($snode) {
		if ($line =~ /^BW\s+:\s+(\d+)/) {
			my $bw = $1;
			print "snode($snode) = $bw\n";
			$SN_BW{$snode} = $bw;
			$snode = 0;
		}
	}

	if ($dnode) {
		if ($line =~ /^\s+(\d+\.\d+\.\d+)\s+\(.*\)\s+\d+\s+\d+\s+(\d+)\s+(\w+\s+\d+)\s+(.*)\d+\s+Hop.s.:(.*)$/) {
			my ($path,$source, $type, $outports, $egredge) = ($1, $2, $3, $4, $5);
			chomp($egredge);
			my @s = split(/\./, $path);
			my $pathsn = $s[0] . "." . $s[1];
			print "path($path) source($source) type($type) outports($outports) egredge($egredge) pathsn($pathsn)=$SN_BW{$pathsn}\n";

			$BWused{$egredge} += $SN_BW{$pathsn};
			$BWusedlist{$egredge} .= $pathsn . ",";
			$type =~ s/\s+//g;
			$Stypelist{$pathsn . ":" . $egredge} .= $type . ",";
		}

		if ($line =~ /^NumPaths to DstNode:/) {
			$dnode = 0;
		}
	}
}


foreach my $egr (sort keys %BWused) {
	#print $egr . " = " . $BWused{$egr} . "{$BWusedlist{$egr}}\n";
	print $egr . " = " . $BWused{$egr} . "\n";
	foreach my $s (sort by_snode split(/,/,$BWusedlist{$egr})) {
		printf "%4s = %9s %s\n", $s, $SN_BW{$s}, $Stypelist{$s . ":" . $egr};
	}
}

sub by_snode() {
	my @as = split(/\./,$a);
	my @bs = split(/\./,$b);
	return ($as[1] <=> $bs[1]);
}

