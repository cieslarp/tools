#!/usr/local/bin/perl

# Remove spaces from filenames and directories recursivly

my $startdir = shift || `pwd`;


chomp($startdir);

open(FLS, "find . |");
while (my $file = <FLS>) {
	chomp($file);
	nospace($file);
}



sub nospace() {
    my $file = shift;
	my $checksp = $file;
	my $base = '';

	if ($file =~ /\//) {
		my @s = split(/\//, $file);
		$checksp = pop(@s);
		$base = join('/',@s) . "/";
	}

    if ($file =~ /\s/) {
		my $nospfile = $file;
        1 while $nospfile =~ s/\s/_/g;
        print "ch($checksp) file[" . $file . "] nosp[" . $nospfile . "]\n" if $debug;
		if (-e $nospfile) {
			print "Cannot move $file to $nospfile: Already exists!\n";
			return $file;
		}
		system("mv -v -- \"$file\" \"$nospfile\"");
        $file = $nospfile;
    }

    return $file;
}

