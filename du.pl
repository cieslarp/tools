#!/usr/local/bin/perl
foreach my $arg (@ARGV) {
    $arg = "--max-depth=$1" if ($arg =~ /-([0-9])/);
}

@out = `/usr/bin/du --bytes @ARGV`;

@sout = sort lsort @out;
foreach $d (@sout) {
   ($size, $dir) = split(/\s+/,$d);
   printf "%13s : %s\n",addcommas($size),$dir;
}

###############################################################
sub lsort {
   ($a1) = split(/\s+/,$a);
   ($b1) = split(/\s+/,$b);
   #print $a1."<=>".$b1." : ", ($a1) <=> ($b1);
   return (rev_human($a1)) <=> (rev_human($b1));
}

###############################################################
sub addcommas() {
   # put commas in the right places in an integer
   my $input = shift;
   1 while $input =~ s/(\d)(\d\d\d)(?!\d)/$1,$2/g;  
   return $input;
}

###############################################################
sub rev_human() {
	my $num = shift;
	my $s = "";
	if ($num =~ /^([\d\.]+)([GMK])$/) {
		$s = $2;
		$num = $1;
	}
	if ($s =~ /G/) {
		return ($num * 1e9);
	} elsif ($s =~ /M/) {
		return ($num * 1e6);
	} elsif ($s =~ /K/) {
		return ($num * 1e3);
	}
	return $num;
}
