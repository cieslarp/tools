#!/usr/local/bin/perl

$TIZ = "";
$FID = "";

while (my $line = <>) {
	if ($line =~ /^Enabled Status:/) {
		if ($line =~ /Activated/) 
		{
			my $allports = join(';', @PL);
			$allports =~ s/\s+//g;
			$allports =~ s/;;/;/g;
			$Zones{$TIZ} = $allports;
		}
		if ($line =~ /Deactivated/) 
		{
			my $allports = join(';', @PL);
			$allports =~ s/\s+//g;
			$allports =~ s/;;/;/g;
			$DeZones{$TIZ} = $allports;
		}
		$TIZ = "";
		@PL = ();
	}

	if (length($TIZ)) {
		if ($line =~ /^Port List:/) {
			my ($junk, $dpl) = split(/:/, $line, 2);
			while ($dpl =~ /,/) {
				#print $dpl;
				chomp($dpl);
				push(@PL, split(/;/, $dpl));
				$dpl = <>;
			}
		}
	}
 
	if ($line =~ /^TI Zone Name:\s+(.*)$/) {
		$TIZ = $FID . $1;
		#print $TIZ . "\n";
		@PL = ();
	}
	
	if ($line =~ /^CURRENT CONTEXT.*\d+\s*,\s*(\d+)/) {
		$FID = "FID=$1 ";
	}
}

printf "%32s : %s\n", "TIZone", "PortList";
foreach my $k (sort keys %Zones) {
	printf "%32s : %s\n", $k, $Zones{$k};
	my @dpl = split(/;/, $Zones{$k});
	my ($f) = ($k =~ /(FID=\d+)/);
	foreach my $dp (@dpl) {
		my ($d,$p) = split(/,/,$dp);
		$Domain[$d]{$p} .= "$k;";
		$Doms{$d . " " . $f}++;
		$Ports{$p}++;
	}
}
foreach my $k (sort keys %DeZones) {
	printf "%32s : %s\n", "(Deactive)" . $k, $DeZones{$k};
	my @dpl = split(/;/, $DeZones{$k});
	my ($f) = ($k =~ /(FID=\d+)/);
	foreach my $dp (@dpl) {
		my ($d,$p) = split(/,/,$dp);
		$Domain[$d]{$p} .= "(deactive)$k;";
		$Doms{$d . " " . $f}++;
		$Ports{$p}++;
	}
}

foreach my $d (sort {$a<=>$b} keys %Doms) {
	printf "Domain %s:\n", $d;
	foreach my $p (sort {$a<=>$b} keys %Ports) {
		if ($d =~ /FID/) { ($d,$f) = split(/\s/,$d); }
		if (length($Domain[$d]{$p})) {
			printf "%4d = %s\n", $p, $Domain[$d]{$p};
		}
	}
}
