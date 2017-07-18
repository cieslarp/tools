#!/usr/local/bin/perl

foreach my $arg (@ARGV) {
	push @files, $arg if -e $arg;
	$Dry++ if $arg =~ /^-d/;
}

foreach $file (@files) {
	if (open(CFILE, $file)) {
		my $ff = $file . ".fix";
		print $file;
		if (open(FIXFILE, ">$ff")) {
			print " -> " . $ff;
			fix_csytle();
			close(FIXFILE);
			close(CFILE);
			print `cp $file $file.bak` unless $Dry;
			print `cp $ff $file` unless $Dry;
		}
		print "\n";
	}
}

sub fix_csytle() {
	foreach my $line (<CFILE>) {
		my $fixline = $line;
		$fixline =~ s/,(\w)/, $1/g unless $fixline =~ /".*,.*"/;
		$fixline =~ s/;(\w)/; $1/g unless $fixline =~ /".*;.*"/;
		$fixline =~ s/(\w)=/$1 =/g unless $fixline =~ /".*=.*"/;
		$fixline =~ s/=(\w)/= $1/g unless $fixline =~ /".*=.*"/;
		$fixline =~ s/(if)\(/$1 (/g unless $fixline =~ /".*\(.*"/;
		$fixline =~ s/(\w)([<>])(\w)/$1 $2 $3/g unless $fixline =~ /".*[<>].*"/;
		$fixline =~ s/\s$/\n/g;
		$fixline =~ s/\){/) {/;
		$fixline =~ /
		print $fixline if $fixline =~ /\/\/\w/;
		printf "%s:$d : %s", $file, $linenum, $fixline if ($fixline ne $line);
		print FIXFILE $fixline;
	}
}
