#!/usr/local/bin/perl
# to - time offset
# Perl script which uses the evt.conf file in current directory to calculate
# the time offset for the data collection engineering logs
#
# Author: Joe Eafanti
# Date: 10/26/06
use strict;

my $evt_conf  = shift || "evt.conf.gz";
my $Partition = shift;

if (! -f $evt_conf) {
    my ($b,$p) = get_dc_base($evt_conf);
    ($b,$p) = get_dc_base() if (! -d $b && length($b) < 1);
    $Partition = $p unless $Partition;
    $evt_conf = $b . "/var" . $Partition . "/config/evt.conf";
    $evt_conf .= ".gz" if (! -e $evt_conf);

}
print "$evt_conf\n";


# File needs to be unzipped before reading
$evt_conf = "zcat $evt_conf |" if ($evt_conf =~ /\.gz$/) && (-e $evt_conf);

open (INFILE,$evt_conf) || die "can't open file $evt_conf";

# get the first line of the file
my $firstline = <INFILE>;
# get the second line - offset in seconds
chomp(my $offset = <INFILE>);

my $totmin  = int ($offset / 60);
my $hours   = int ($totmin / 60);
my $seconds = int ((($offset/60) - $totmin) * 60);
my $minutes = int ($totmin - ($hours * 60));

print "Seconds Offset [$offset] => Time Offset: [$hours:$minutes:$seconds]\n";
close(INFILE);

# Get the base directory for this data collect based on input or pwd
# Search for var[0-9] for the partition and Active or Standby as the base
sub get_dc_base()
{
    chomp (my $start = shift || `pwd`);
    my $dcbase = "";
    my $part   = 0;
    my @dirs = split(/\//, $start);
    while(@dirs) {
        my $sd = pop(@dirs);
        ($part) = $sd =~ /var(\d+)/ if $sd =~ /var/;
        return(join("/",@dirs,$sd),$part) if $sd =~ /Active|Standby/;
    }
    return ($dcbase,$part);
}
