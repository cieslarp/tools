#!/usr/local/bin/perl
$just_float = 1 if $0 =~ /number/;

$LastTime = 0.0;
$FirstTime = 0.0;

while (my $line = <>) {
	if (my ($h, $m, $s, $ms) = $line =~ /(\d{2}):(\d{2}):(\d{2})\.(\d+)/) {
		my $hs = $h * 60 * 60;
		my $mns = $m * 60;
		my $hms = $hs + $mns + $s;

		my $float = $hms . "." . $ms;

		my $delta = ($LastTime > 0.0) ? ($float - $LastTime) : $LastTime;
		my $runtime = ($FirstTime > 0.0) ? ($float - $FirstTime) : $FirstTime;

		my $string = sprintf "$float:[%6.4f %6.4f] $line", $delta, $runtime;

		if ($just_float) {
			printf "$float: $line";
		} else {
			printf "[%6.6f %6.6f] $line", $delta, $runtime;
		}

		$LastTime = $float;
		$FirstTime = $float if ($FirstTime == 0.0);
	}
}
