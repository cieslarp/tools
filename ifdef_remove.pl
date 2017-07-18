#!/usr/local/bin/perl

foreach my $arg (@ARGV) {
	if ($arg =~ /^-(\w)(\w*)$/) {
		my $p = $1;
		my $v = $2;
		push(@defines, split(/,/,$v)) if ($p eq "d");
	} elsif (-f $arg) {
		$file = $arg;
	}
}

print "File($file)\n";
$defs = join('|',@defines);
print "Defines(@defines) defs($defs)\n";

open(FILE, $file) || die "Unable to open file: $file\n";
while (my $line = <FILE>) {
	chomp($line);
	if ($line =~ /^\s*#if\s+\!/) {
		print "Del: " . $line . "\n" if $line =~ /$defs/;
		$del_until_e = 1;
	} elsif ($line =~ /^\s*#e/) {
		$del_until_e = 0;
		print "Del done: " . $line . "\n";
	}
}
