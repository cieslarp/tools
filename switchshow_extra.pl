#!/usr/local/bin/perl


# Given the input file (probably from a support save, look for enhanced data to add to the switchshow output)

$swnum = 0;
$Switch = "";
$in_bladeportmap = "";

while (my $line = <>) {
	chomp($line);

	if ($line =~ /^CURRENT CONTEXT -- (\d+) , (\d+)/) {
		$swnum = $1;
		$fid = $2;
	}

	if ($line =~ /^bladeportmap\s+(\d+)/) {
		$in_bladeportmap = "S" . $1;
	}
	if ($in_bladeportmap) {
		save_bladeportmap(substr($in_bladeportmap,1),$line,$Switch);
	}
	if ($line =~ /^real/) {
		$in_bladeportmap = "";
	}
	$inss = 1 if ($line =~ /^switchName/);
	$inss = 0 if ($line =~ /^real/);

	if ($inss) {
		$SS{$fid} = $line;
		print $line . "\n";
	}
}

sub save_bladeportmap() {
	my $slot = shift;
	my $line = shift;
	my $desc = shift;

	chomp($line);
	if ($line =~ /^DIS|^ENB/) {
		my @s = split(/\s+/,$line);
		my $sscp = $desc . "\t" . $slot . "/" . $s[9] . "/" . $s[5];
		print "BPM $sscp [$line]\n" if $debug > 2;
		$Bladeportmap{$sscp} = $line;
	}
}
