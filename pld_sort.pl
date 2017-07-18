#!/usr/local/bin/perl

$Search = shift || "*PLOG*";

$SNO = -1;
 

while (my $file = glob($Search)) {
	print "File: $file\n";
	open(FILE, "$file") || next;
	while (my $line = <FILE>) {
		if ($line =~ /CURRENT CONTEXT -- (\d+) , (\d+)/) {
			$SNO = $1;
			$FID = $2;
		}
		printf "[%3d] $line", $FID;
	}
	close(FILE);
}
