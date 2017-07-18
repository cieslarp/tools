#!/usr/local/bin/perl
$debug = 0;

while (my $line = <>) {
	if ($line =~ /p(.*t)statsshow\s+(\w+.*\w*)/) {
		$ptype = $1;
		$port = $2;
		print "ptype($ptype) port($port)\n" if $debug;
	}
	elsif ($line =~ /tim_txcrd_z\s+/) {
		#tim_txcrd_z             0           Time TX Credit Zero (2.5Us ticks)
		my @s = split(/\s+/,$line);
		if ($FidDomPort{$port}) {
			$key = $FidDomPort{$port};
		} else {
			$key = join(":", 0, 0, $port);
		}
		print "key($key) p($port) z($s[1])\n" if $debug;
		$Total{$key} = $s[1];
	} 
	elsif ($line =~ /tim_txcrd_z_vc/) {
		#tim_txcrd_z_vc  0- 3:  0           0           0           0         
		#tim_txcrd_z_vc  4- 7:  0           0           0           0         
		#tim_txcrd_z_vc  8-11:  0           0           0           0         
		#tim_txcrd_z_vc 12-15:  0           0           0           0         
	}
	elsif ($line =~ /^switchshow/) {
		$In_switchshow = 1;
	}
	elsif ($line =~ /^sys\s+/) {
		$In_switchshow = 0;
	}
	elsif ($In_switchshow && $line =~ /^\s+(\d+)\s+/) {
		my $swport = $1;
		chomp($line);
		my $key = join(":",$FID,$Domain,$swport);
		print "key($key) FID($FID) D($Domain) sw($swport) l($line)\n" if $debug;
		$SwitchShow{$key} = $line;
		$FidDomPort{$swport} = $key;
	}
	elsif ($In_switchshow && $line =~ /^switchDomain:\s*(\w+)/) {
		$Domain = $1;
	}
	elsif ($In_switchshow && $line =~ /^switchName:\s*(\w+)/) {
		$Name = $1;
	}
	elsif ($line =~ /^CURRENT CONTEXT --\s*\d*\s*,\s*(\d+)/) {
		$FID = $1;
	}
	elsif ($line =~ /^portId:\s+(\w+)/) {
		$PID = $1;
	}
}

printf "FID:Dom:Port:      Total \n", $port, $Total{$port};
foreach my $port (sort {$Total{$a} <=> $Total{$b}} keys %Total) {
	if ($Total{$port} > 0) {
		print "%12s ", $port if $debug;;
		printf "F:%-3d D:%-3d P:%-4d: %10d : %s\n", split(/:/,$port), $Total{$port}, $SwitchShow{$port};
	}
}
