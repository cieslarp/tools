#!/usr/local/bin/perl
my $debug = 0;
my $index = 0;
my $Width = 34;
my @LogEntries = ();
my @MIDs = ();
my $ShowMID = 0;
my $ShowMySwitch = 0;

my $ss = "Rte";
if ($0 =~ /_(.*)$/) {
	$ss = $1;
}

if ($ss =~ /all/i) {
	$inSS = 0xffffffff;
	$Sort = 1;
}

while ($ARGV[0] =~ /^-/) {
	if ($ARGV[0] =~ /^-.*m(.+)/) {
		push(@MIDs , split(/,/,$1));
		print "MID(@MIDs)\n";
		$ss = "none";
	}
	if ($ARGV[0] =~ /^-.*d(\d*)/) {
		my $level = $1;
		if ($level) { $debug = $level; }
		else { $debug++; }
		print "debug($debug)\n";
	}
	if ($ARGV[0] =~ /^-.*t/) {
		print "delta\n";
		$do_delta++;
	}
	if ($ARGV[0] =~ /^-.*Y/) {
		print "ShowMySwitch\n";
		$ShowMySwitch++;
		$Width += 5;
	}
	if ($ARGV[0] =~ /^-.*M/) {
		print "ShowMID\n";
		$ShowMID++;
		$Width += 30;
	}
	shift(@ARGV);
}

$Sort = 1 if (($do_delta) || ((scalar @MIDs) > 1));
$CheckMid = join("\$\|^", @MIDs);
$CheckMid = "^" . $CheckMid . "\$";
print "ss($ss) MIDs(@MIDs)=$CheckMid do_delta($do_delta) debug($debug) Sort($Sort)\n";

my @Input = <>;

while (@Input) {
	my $line = shift @Input;
	chomp($line);
	
	if ($line =~ /Buffer #.*\(mid = (\d+),/) { $MID        = $1; $SID = "";}
	$SID        = $1 && $MIDsubs[$MID]++ if ($line =~ /Buffer #.*\(mid = \d+,\s+sid\s+=\s+(\d+),/);
	$NumEntries = $1 if ($line =~ /Number of Entries:\s+(\d+)/);
	$Lifetime   = $1 if ($line =~ /Lifetime count:\s+(\d+)/);
	$NumWraps   = $1 if ($line =~ /Number of wraps:\s+(\d+)/);
	$LastEntry  = $1 if ($line =~ /Last entry:\s+(\w+)/);
	if ($line =~ /Instance:\s+(\w+)/) {
		$Instance   = $1;
		$PrintHeader = 1;
		$PrintFooter = 1;
	}

	if ($ss eq "none") { $inSS = ($MID =~ /$CheckMid/) ? 1 : 0; }
	if ($line =~ /Instance:\s+$ss/) { $inSS = 2; print $line . "\n";}

	if ($inSS) {
		if ($line =~ /,(\d\d)\d+\s+(\w{3}\s\w{3}\s+\d+\s+\d+:\d+:\d+\.\d{6}\s+\d{4}\(.*\))/) {
			$MySwitch = $1;
			$DateString = $2;
			print "Got ds($DateString) from:[$line]\n" if $debug;
		}

		if ($line =~ /Time Stamp\s+EvtID\s+EvtFmt/) {
			print "MID:$Instance string log: $line\n" if $debug;
		}

		my @s = split(/\t| {4}/,$line);

		#2467    Wed Apr 27 10:34:38.757316 2016(UTC)

		#1116    Switch 0; Thu Dec 30 12:26:37.355407 2010(UTC)
		if ($line =~ /^\d+\s+(Switch\s+\d+);/) {
			my $entry = sprintf "=" x 10 . "===Instance:%s(%d) Num=(%d) Wraps=(%d) Total=(%d)===", $Instance, $MID, $NumEntries, $NumWraps, $Lifetime;
			log_entry($DateString, "--$Instance($1)--", (($PrintHeader) ? $entry : "-- $Instance($MID) $1 --"));
			$PrintHeader = 0;
		} elsif ($s[0] =~ /^\d+$/) {
			my $log = "";
			my @loglines;
			
			printf "P(%d) sub(%s) " . "(%s)" x $#s . "\n", $s[0], substr($s[3],11,15), @s if $debug;
			$DateString = $s[3] if $s[3];
			print "ds($DateString)\n" if $debug;

			# Keep getting lines until an empty line, then cat them all together
			while ($Input[0] !~ /^$/) {
				my $next = shift @Input;
				chomp($next);
				last unless $next;
				print "next($next) added to log\n" if $debug;
				push(@loglines, $next);
			}
			
			if ($PrintHeader) {
				my $entry = sprintf "=" x 10 . "===Instance:%s(%d) Num=(%d) Wraps=(%d) Total=(%d)===", $Instance, $MID, $NumEntries, $NumWraps, $Lifetime;
				log_entry($DateString, "===$Instance===", $entry);
				$PrintHeader = 0;
			}

			my $log = join(' ', @loglines);
			if ($ShowMySwitch) {
				$log = "Sw($MySwitch) " . $log;
			}
			if ($ShowMID) {
				if ($MIDsubs[$MID] > 1) {
					$log = (sprintf "%3d%3s", $MID, ($SID) ? ":" . $SID . " " : "   ") . $log;
				} else {
					$log = (sprintf "%3d : ", $MID) . $log;
				}
			} elsif ($MIDsubs[$MID] > 1) {
				$log = ":" . $SID . ":" . $log;
			}

			#lookup PTIO commands to ease debugging ASIC issues
			if ($log =~ /cmd[\s=]([A-Fa-f0-9x]{6,10})/ or $log =~ /PTIO ([A-Fa-f0-9x]{6,10})/) {
				my $cmd = $1;
				$cmd =~ s/^0x//;
				$cmd =~ s/^0+//g;
				%PTIO_Lookup = get_PTIO_decode() unless defined %PTIO_Lookup;
				#my @PTD = split(/,/,`ptio_dec | grep $cmd`);
				my $ptio = $PTIO_Lookup{$cmd};
				print "PTIO command detected: $cmd = [$ptio] (@PTD)\n" if $debug;
				$log =~ s/$cmd/$cmd($ptio)/ if $ptio;
			}
			
			#decode LLI interrupts: INTR LLI cz,d,ns,s(ps),e,c 00000000 00144000 00170007 00034007(00034007) 001c0040 4000f0c7
			if ($log =~ /INTR LLI cz,/) {
				$log = decode_lli($log, $MID);
			}

			log_entry($DateString, $s[1], $log);
		} elsif ($line =~ /^#+$/) {
			$inSS--;
		} elsif ($line =~ /^\s+(\d+:\d+:\d+\.\d{6})\s*(.*)$/) { # 12:26:39.355810
			my $timestr = $1;
			my $entry = $2;
			my @s = split(/\s+/, $DateString);
			$DateString = substr($DateString,0,11) . $timestr . " " . $s[-1];
			print "t($timestr) ds($DateString) e($entry)\n" if $debug;
			$MIDCount{$Instance}++;
			$entry = (sprintf "%3d%3s", $MID, ($SID) ? ":" . $SID . " " : "   ") . $entry if $ShowMID;
			log_entry($DateString, "$Instance(" . $MIDCount{$Instance} . ")", $entry);
		}

	}
}

if ($Sort) {
	my @sorted = sort by_dti_hash_ref @LogEntries;
	my $PD= 0, $PT = 0;
	print "sorted=$#sorted\n" if $debug;
	foreach my $hr (@sorted) {
		my $d = get_delta($hr);

		if ($do_delta < 2) {
			my $s = "";
			if ($d > 1000000.0)	{ $s .= "."; } 
			if ($d > 100000.0)	{ $s .= "."; } 
			if ($d > 10000.0)	{ $s .= "."; } 
			if ($d > 1000.0)	{ $s .= "."; } 
			if ($d > 100.0)		{ $s .= "."; }
			if ($d > 10.0)		{ $s .= "."; }
			if ($d > 1.0) 		{ $s .= "."; }
			print "$s\n" if (length($s));
		}
		printf "%10.3f ", $d if ($do_delta);
		print $hr->{Entry};
	}
}








##################################
sub log_entry() {
	my $date_string = shift;
	my $trace_entry = shift;
	my $log_string = shift;
	my $te = $trace_entry;

	if (length($trace_entry) < ($Width-4)) {
		$month = substr($date_string,4,3);
		$te = sprintf("%-" . ($Width-3) . "s%3s", $trace_entry, $month);
	}
	printf "ds($date_string) trace($trace_entry) te($te) ls($log_string) month($month)\n" if $debug;
	my $log = sprintf "%-" . $Width . "s %2s.%15s %s\n", $te, substr($date_string,8,2), substr($date_string,11,15), $log_string;

	if ($Sort) {
		my $dates = $date_string;
		$dates =~ s/\D+//g;
		my ($date, $time) = get_date_time($date_string);
		print "($date_string) => parsed to $index:($date,$time)\n" if $debug;
		my $log_ref = {
			'Date'	=> $date,
			'Time'	=> $time,
			'Entry'	=> $log,
			'Index' => $index
		};
		push(@LogEntries, $log_ref);
		$index++;
	}
	else {
		printf $log;
	}
}



##################################
sub get_date_time() {
	my $ts = shift;
	my %Mon = ( Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6, Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12 );
	# Mon Jan  5 09:38:50.-289960 2009(UTC)
	my ($d,$m,$md,$t,$ytz) = split(/\s+/, $ts);
	my ($y,$tz) = split(/\)|\(/,$ytz);
	my ($tim, $ms) = split(/\./,$t);
	my ($hr,$mn,$sec) = split(/:/,$tim);
	my $date = sprintf("%4d%02d%02d%05d", $y , $Mon{$m} , $md, $hr*3600 + $mn*60 + $sec);
	print "get_date_time($ts) => [$d,$m,$md,$t($tim,$ms),$ytz($y,$tz) date=$date ms=$ms\n" if $debug>2;
	return ($date,$ms);
}



##################################
sub by_dti_hash_ref() {
	return ($a->{Date} <=> $b->{Date} || $a->{Time} <=> $b->{Time} || $a->{Index} <=> $b->{Index});
}



##################################
sub get_delta() {
	my $hr = shift;
	my $delta_string = "";

	$PD = $hr->{Date} unless $PD;
	$PT = $hr->{Time} unless $PT;

	my $dd = ($hr->{Date} - $PD);
	my $dt = ($hr->{Time} - $PT);
	if ($dt < 0) {
		$dd--;
		$dt = 1e6 + $dt;
	}
	$delta_string = sprintf("[%3d:%6d] (%s,%s) ", $dd, $dt, $hr->{Date}, $hr->{Time});
	if ($do_delta < 2) {
		$PD = $hr->{Date};
		$PT = $hr->{Time};
	}

	#return $delta_string;
	return sprintf("%d.%06d", $dd, $dt);
}



###################################
sub get_PTIO_decode() {
	%PTIOs = ();
	my @ptio_dec = `ptio_dec`;
	foreach my $ptio_s (@ptio_dec) {
		my @ptio_l = split(/,/,$ptio_s);
		$ptio_l[4] =~ s/^0x//;
		$ptio_l[4] =~ s/^0+//g;
		print "ptio_l[4] = (" . $ptio_l[4] . ") ptio=(" . $ptio_l[0] . ")\n" if $debug>2;
		$PTIOs{$ptio_l[4]} = $ptio_l[0] if $ptio_l[4] =~ /[A-Fa-f0-9]/;
	}

	printf "PTIOs keys=%d\n" , scalar keys %PTIOs if $debug;

	return %PTIOs;
}


###########################################################
#decode LLI interrupts: INTR LLI cz,d,ns,s(ps),e,c 00000000 00144000 00170007 00034007(00034007) 001c0040 4000f0c7
sub decode_lli() {
	my $llilog = shift;
	my $mid = shift;
    #ASIC_RASTRACE_STATE(C4_INTR_LLI_STS,
               #c4_phyp->pt,
               #lli_cause & ASIC_RD4B(phyregp->fpl_lli_intr_enable_clr),
               #ASIC_RD4B(phyregp->fpl_lli_def),
               #ASIC_RD4B(phyregp->fpl_lli_ns_status),
               #ASIC_RD4B(phyregp->fpl_lli_intr_status),
               #lli_cause,
               #ASIC_RD4B(phyregp->fpl_lli_intr_enable_clr),

	@LLIbit = ( 0, 0, 0, 0, 0, 0,
		"SN_CHANGE",
		"LK_CHANGE",
		"<res8>",
		"<res9>",
		"LRTT_RUN",
		"<res11>",
		"ARBF0_RCVD",
		"<res13>",
		"HSS_SIG_DET",
		"TF_LOCK",
		"LOSYNC",
		"LOSYNC_TO",
		"RX_SIG",
		"LASER_FLT",
		"MOD_CHANGED",
		"<res21>",
		"CNST_MARK_RCVD",
		"MARK_RCVD",
		"LK_TEST_GOOD",
		"PCS_R_STATUS",
		"LK_TEST_DONE",
		"LK_TRAIN_DONE",
		"RX_UNDER",
		"RX_OVER",
		"TX_UNDER",
		"TX_OVER");

	@Prims = ("Idle", "LRR", "LR", "OLS", "NOS", "ARB", "<res>", "none");

##define C4_LLIS_PRIMITIVE       (RBIT_2 | \
#                                 RBIT_1 | \
#                                                                  RBIT_0)    /* prim seq rcvd: LLI_{IDLE,LRR,LR,OLS,NOS,ARB,UNKNOWN} */
#
	#for now just assume all LLIs are the same
	if ($mid > 0) {
		my $cause = "";
		my @s = split(/\s+/,$llilog);
		my $ns = hex($s[-4]);
		my $cs = hex($s[-6]);
		printf "decode_lli: cs($cs):%x ns($ns):%x llilog[$llilog]\n", $cs, $ns if $debug;
		my $prim = ($ns & 0x7);
		print "prim($Prims[$prim])\n" if $debug;
		$llilog .= " prim=$prim($Prims[$prim])";
		for my $i (6..31) {
			if ($ns & (1<<$i)) {
				print "$i:$LLIbit[$i]\n" if $debug;
				$llilog .= " $i:$LLIbit[$i]";
			}
			if ($cs & (1<<$i)) {
				$cause .= (length($cause) ? ",$LLIbit[$i]" : "$LLIbit[$i]");
			}
		}
		print "cause($cause)\n" if $debug;
		$llilog =~ s/e,c\s+(\w+)\s+/e,c $1($cause) / if length($cause);
		print "llilog:$llilog\n" if $debug;
	}
	return $llilog;
}
