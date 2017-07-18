#!/usr/local/bin/perl

$debug = 1;
die "$0 <var> <range> <cmds> end" unless scalar @ARGV > 3;

my $var = shift;
my $range = shift;
my @cmds = @ARGV;

pop(@cmds) if $cmds[-1] =~ /end|done/;

foreach my $j (eval($range)) {
	print "it[$j] var[$var] r[$range] [@cmds]\n" if $debug;
	my $cmd = join(" ", @cmds);
	print "cmd[$cmd]\n" if $debug;
	$cmd =~ s/JJ/$j/g;
	print "aftercmd[$cmd]\n" if $debug;
	system($cmd);
}
