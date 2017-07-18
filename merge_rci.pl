#!/usr/local/bin/perl

while (my $line = <>) {
	chomp($line);
	my @s = split(/:/,$line);
	my ($file, $fullrev) = split(/@@/,$s[0]);

	if ($fullrev =~ /main.*\/(\d+)\s*$/) {
		$prev = $1 - 1;
		$prevrev = $fullrev;
		$prevrev =~ s/\/(\d+)\s*$/\/$prev/;
		#printf "f[$fullrev] p[$prev] pr[$prevrev]\n";
		#printf "td $s[0]\n";
		#printf "vd %s %s@\@%s\n", $file, $file , $fullrev;
		#printf "cleartool findmerge $file -fver $fullrev -merge -gmerge\n";
		printf "vd %s %s@\@%s %s@\@%s\n", $file, $file , $fullrev, $file, $prevrev;
	}
}
