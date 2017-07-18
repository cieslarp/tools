#!/usr/local/bin/perl

$predate = 0;
$L = 1;
while (my $line = <>) {
	chomp($line);
	my ($file, $string) = split(/:/,$line,2);
	my @s = split(/:/,$line, 4);

	$s[2] =~ s/\.//g;
	my ($sec,$ms) = split(/\./,$s[3]);
	my $date = sprintf("%2d%02d%02d%03d", $s[0], $s[1], $sec, $ms);
	printf "date[%s] %d, %d, %d, %d, %d\n", $date, $s[1], $s[2], $sec, $ms, $sameindex if $debug;
	if ($predate == $date) { 
		$sameindex++;
	} else {
		$sameindex = 0;
	}
	$predate = $date;
	$PLD{$date . "$sameindex"} = $string;
	$FLD{$date . "$sameindex"} = $file;
	$L = length($file) if (length($file) > $L);
}

foreach my $k (sort {$a <=> $b} keys(%PLD)) {
	printf "[%s] : ", $k if $debug;
	printf "%-" . $L . "s %s\n", $FLD{$k}, $PLD{$k};
}
