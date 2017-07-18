#!/usr/local/bin/perl

while (my $line = <>) {
	if ($line =~ /^(\w+)\s+(\d+)m(\d+.\d+)s$/) {
		my ($type, $minutes, $seconds) = ($1, $2, $3);
		$Total_s{$type} += $seconds + (60 * $minutes);
		$Total_m{$type} = $Total_s{$type} / 60;
		printf "%8s: %4dm %6.3fs (Total: %6.2fm %6.3fs)\n", $type, $minutes, $seconds, $Total_m{$type}, $Total_s{$type};
	}
	if ($line =~ /Asic Chip/) { print $line; }
}
foreach my $type ("real", "user", "sys") {
	printf "Total %s: %6.2fm(%6.3fs)\n", $type, $Total_m{$type}, $Total_s{$type};
}
