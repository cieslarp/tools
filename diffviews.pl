#!/usr/bin/perl
use POSIX qw(strftime);
$|=1;
$now_string = strftime "%d%b%Y_%H%M%S", localtime;
$debug = 1;
$otherview = '';
$branch = "@@/man/neos_6.1/LATEST";
$bld = "@@/main/neos_6.1/NEOS61_BLD_25";

foreach $arg (@ARGV) {
    if ($arg =~ /^-/) {
        $debug = substr($arg,2) if $arg =~ /-d/;
    }
    elsif ($otherview eq '') {
        $otherview = $arg;
    } else {
        push(@dirs,$arg);
    }
}
#fcssmain.c@@/main/neos_6.1/NEOS61_BLD_25

die "Must specify another view to diff\n" unless $otherview;

push(@dirs,"/vobs/sw/") unless scalar @dirs;

foreach my $dir (@dirs) {
    die "Could not find $dir\n" unless -d $dir;
    $dir = $dir . "/" unless $dir =~ /\/$/;
    @files = `fls $dir .c .cpp .h .pl`;
    print "file count=$#files\n" if $debug;
    foreach my $f (@files) {
        chomp($f);
        my $of = "/view/$otherview".$f;
        if ((-e $f) && (-e $of)) {
            my $diff = `diff $f $of`;
            if (length($diff)>0) {
                print STDERR "tkdiff $f $of &\n";
                print "-=" x 20 . $f . "=-" x 20 . "\n";
                print $diff;
            }
        }
    }
    print "\n" if $debug;
}
