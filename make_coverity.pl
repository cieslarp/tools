#!/usr/local/bin/perl
use File::Basename;

my $sel = shift || "";
my $swbd = glob("/vobs/projects/springboard/build/swbd$sel*");
print "swbd($swbd)\n";

my $outs = shift || "cleartool lsco -avob -s -cview |";

#foreach my $dir (@dirs) {
open(DIRFILE, $outs) || die "Unable to spawn outdirs($outs)\n";
while (my $dir = <DIRFILE>) {
	chomp($dir);
	print "indir($dir)\n";
	$dir = dirname($dir) if (! -d $dir);
	next if $Bases{$dir};
	#print "dir($dir) dirname(" . dirname($dir) . ") basename(" . basename($dir) . ")\n";
	if (IsCoverityNeeded($dir, "/vobs/projects/springboard/make/cov_gk_info")) {
		my $mcp = "coverity-parallel"; # is there a way to tell if a dir can support coverity-parallel?
		my $bdir = $dir;
		my $up_one = 0;

		$bdir =~ s/^.*fabos/$swbd\/fabos/;

		do_make: 
		print ":::Make $mcp: " . $bdir . "\n";
		open(MCP, "(cd $bdir; make $mcp 2>&1) |") || die "Unable to spawn make in $bdir\n";
		while (my $o = <MCP>) {
			print $o if $debug;
			if ($o =~ /No rule to make target/) {
				print $o;
				if ($mcp =~ /parallel/) {
					$mcp = "coverity";
					close MCP;
					goto do_make;
				} elsif ($up_one == 0) {
					my @sd = split(/\//,$bdir);
					pop(@sd);
					$bdir = join('/',@sd);
					close MCP;
					$up_one++;
					goto do_make;
				}
			}
			if ($o !~ /For help see/) {
				push(@Results, $o) if $o =~ /^\*\*\* /;
			}
			
		}
		close(MCP);
		
	} else {
		print "Skip: $dir \n";
	}
	$Bases{$dir}++;
}
printf "Results: count:%d\n", scalar @Results;
print @Results;




############################################
sub IsCoverityNeeded() {
    my ($filename, $dirList) = @_;
    my $dirPath = dirname($filename);
    my $matched = 0;
	$dirPath = $filename if -d $filename;

    if (-f "${dirList}" && -s "${dirList}") {
        open(FILE, ${dirList}) or die "Error: $dirList cannot be opened";

        while (<FILE>) {
            chomp;
            my $line = $_;
            $line =~ s/^\s+//;
            $line =~ s/\s+$//;
			#print "line($line) vs filename($filename) vs path($dirPath)\n";
            if (!$line || $line =~ /^\s*#/) { # comment or an empty line
                next;
            }

            # Exclude directories beginning with a '-'
            if ($line =~ /^-/) {
                my $excluded = substr($line, 1);
                if ($dirPath =~ /$excluded/) {
					$matched = 0;
                    last;
                }
            }

            if ($dirPath =~ /$line/) {
                $matched = 1;
                last;                                                                                                                                  
            }
        }
        close(FILE);

    }

	if ($dirPath =~ /raslog\/xml$|asic\/proto$/) {
		$matched = 0; # Skip these directories
	}

    return $matched;
}

