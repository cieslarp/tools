#!/usr/local/bin/perl

#bigbangagt_txt.log.gz:20061110:050407.421789 epsa 024 000: 26158 82 0 CEI GET 10.2.153.175: id=19001 (BBPERFPORTENTRY), rc=-1002 (Object not
 

while (chomp(my $line = <>))
{
    my ($file, $datet, $msg) = $line =~ /(.*):(\d{8}:\d{6}\.\d{6})( .*)/;
    if ($msg) 
    {
        $file = sprintf("%-23s",$file);
        $Msg{$file . $msg} = join "\t", $Msg{$file . $msg}, $datet;
        #print "file=[$file] dt[$datet] msg=[" . length($msg) . "]\n";
    }
}

foreach my $k (sort datesort keys %Msg)
{
    $Msg{$k} =~ s/^\s+//g;
    my @d = split(/\t/,$Msg{$k});

    printtobe($d[0]);

    my $inschar = " ";
    if ($d[-1] ne $d[0])
    {
        my $key = $k;
        if ($#d > 1)
        {
            $key = "(" . $#d . ")" . $k;
            $inschar = ">";
        }
        $ToBePrinted{$key} = $d[-1];
    } 

    printf "%-28s$k\n", ($d[0] . $inschar);
}

foreach my $ik (sort tbsort keys %ToBePrinted) 
{
    printf "%-28s<$ik\n", $ToBePrinted{$ik};
}

sub printtobe()
{
    my $curd = shift;

    foreach my $ik (sort tbsort keys %ToBePrinted) 
    {
        if (datecomp($ToBePrinted{$ik},$curd) < 0)
        {
            printf "%-28s<\n", $ToBePrinted{$ik}."<$ik";
            delete $ToBePrinted{$ik};
        }
    }
}

sub datesort()
{
    datecomp($Msg{$a},$Msg{$b});
}

sub tbsort()
{
    datecomp($ToBePrinted{$a},$ToBePrinted{$b});
}


sub datecomp()
{
    my $a = shift;
    my $b = shift;
    my ($ad, $at, $au) = $a =~ /(\d{8}):(\d{6})\.(\d{6})/;
    my ($bd, $bt, $bu) = $b =~ /(\d{8}):(\d{6})\.(\d{6})/;
    $ad <=> $bd || $at <=> $bt || $au <=> $bu;
}
