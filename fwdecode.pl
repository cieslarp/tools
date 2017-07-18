#!/usr/local/bin/perl

$Debug = 0;

foreach my $arg (@ARGV) {
	if ($arg =~ /^-/) {
		$Debug++ if $arg =~ /^-d/;
	} else {
		push(@input, $arg);
	}
}

push(@input, "*FABRIC_WATCH*") unless scalar @input;

foreach my $in (@input) {
	print "IN[$in]\n" if $Debug;
	if ($in =~ /^\*/ || -e $in) { #glob
		foreach my $file (glob($in)) {
			my $cat = ($file =~ /\.gz$/) ? "zcat" : "cat";
			print "$cat($file)\n" if $Debug;
			open(FWFILE, "$cat $file |") || die;
			while (my $line = <FWFILE>) {
				if ($line =~ /^=+\s+THE INSTANCE OF SWITCH IS (\d+)/) { $fid = $1; }
				if ($line =~ /^=+\s\[(\D+)(\d+)\]=+$/) {
					$statn = $1;
					$port = $2;
					print "FID=$fid stat=$statn port=$port\n";
					$PortsWithStat{$statn} .= "$port,";
					$StatsForPort{$port} .= "$statn,";
				}
			}
		}
	}
}


foreach my $s (keys %PortsWithStat) {
	print "$s: $PortsWithStat{$s}\n";
}
