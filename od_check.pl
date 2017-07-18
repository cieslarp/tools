#!/usr/local/bin/perl
$Cline = "";
$ASMcount = 0;

while (my $line = <>) {
	if ($line =~ /^\/.*:\d+$/) { # C line
		chomp($line);
		if ($Cline) {
			$lc{$Cline} += $ASMcount;
			$alc{$Cline} = $ASMcount;
		}
		$Cline = $line;
		$ASMcount = 0;
		$clc{$line}++;
	}
	if ($line =~ /^\s+\w+:\s+\w{2}\s\w{2}\s\w{2}\s\w{2}\s+/) { # ASM line
		$ASMcount++;
		$allASM++;
	}
}
$lc{$Cline} += $ASMcount;

print "ASM inst: $allASM\n";
for my $s (sort by_count keys %lc) {
	printf "%10d x %4d = %10d : $s\n", $clc{$s}, $alc{$s}, $lc{$s}, $s;
	last if $i++ > 40;
}


sub by_count() {
	return $lc{$b} <=> $lc{$a};
}
