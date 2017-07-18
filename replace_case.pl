#!/usr/local/bin/perl

# Search for the provided case insensitive string, and replace the text in all files specified but keep the case the same
# e.g. replace "green" "blue" would change:
# Green -> Blue
# GREEN -> BLUE
# gReen -> bLue

my $Search = lc(shift) || die "No search given\n";
my $Replace = lc(shift) || die "No replace given\n";
my @Rs = split(//,$Replace);

print STDERR "S($Search) R($Replace)\n";

foreach my $a (@ARGV) {
	print "a:$a\n";
	if (-e $a) {
		print "af: $a\n";
		push(@files, $a);
	}
}

foreach my $in (<>) {
	chomp($in);
	if (-e $in) {
		print "sf: $in\n";
		push(@files, $in);
	}
}

foreach my $f (@files) {
	print "searching for $Search to replace with $Replace in file $f\n";
	if (open(F, $f)) {
		if (open(R, ">$f.rep")) {
			foreach my $line (<F>) {
				chomp($line);
				if ($line =~ /($Search)/i) {
					my $m = $1;
					my @ups = ();
					my $r = "";
					my $j = 0;
					my @ms = split(//,$m);

					foreach my $i (0 .. length($Replace)) {
						push(@ups, ($ms[$j] =~ /\p{Uppercase}/) ? "uc" : "lc");
						$r .= ($ms[$j] =~ /\p{Uppercase}/) ? uc($Rs[$i]) : lc($Rs[$i]);
						if ($i < $#ms) {
							$j++;
						}
					}
					printf "found s:$Search in line($line) m($m) r($r)@ups rep($Replace)=%d\n", length($Replace);
					$line =~ s/$m/$r/g;
				}

				print R $line . "\n";
			}
			close(R);
		} else {
			print "Could not create file:$f.rep\n";
		}
		close(F);
	} else {
		print "Could not open file:$f\n";
	}
}
