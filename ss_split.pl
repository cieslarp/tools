#!/usr/local/bin/perl

while (my $f = glob("*")) {
	my @s = split(/-/,$f);
	next if -d $f;
	print "subdir($s[0]) file($f)\n";
	print `mkdir $s[0]` unless -d $s[0];
	print `mv $f $s[0]` unless -e "$s[0]/$f";
}
