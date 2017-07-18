#!/usr/bin/perl
use POSIX qw(strftime);
$|=1;
$now_string = strftime "%d%b%Y_%H%M%S", localtime;
$debug = 1;
$otherview = '';
$branch = "@@/main/neos_6.1/";
$bldA = "NEOS61_BLD_25";
$bldB = "NEOS61_BLD_26";

foreach $arg (@ARGV) {
    if ($arg =~ /^-/) {
        $debug = substr($arg,2) if $arg =~ /-d/;
        $bldA  = substr($arg,2) if $arg =~ /-a/;
        $bldB  = substr($arg,2) if $arg =~ /-b/;
    } else {
        push(@dirs,$arg);
    }
}

push(@dirs,"/vobs/sw/") unless scalar @dirs;

foreach my $dir (@dirs) {
    die "Could not find $dir\n" unless -d $dir;
    $dir = $dir . "/" unless $dir =~ /\/$/;
    @files = `fls $dir .c .cpp .h .pl`;
    print "file count=$#files\n" if $debug;
    foreach my $f (@files) {
        chomp($f);
        my $af = $f . $branch . $bldA;
        my $bf = $f . $branch . $bldB;
        if ((-e $af) && (-e $bf)) {
            my $diff = `diff $af $bf`;
            if (length($diff)>0) {
                print STDERR "tkdiff $af $bf &\n";
                print "-=" x 20 . $f . "=-" x 20 . "\n";
                print $diff;
            }
        }
    }
    print "\n" if $debug;
}
