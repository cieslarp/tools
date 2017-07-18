#!/usr/local/bin/perl
my $core = 0;
my @pid = (0,0);
my @process = ("<pid0>", "<pid1");
$debug = 0; 
my $nTime = "Tn";
my $nFuncCount = "Fc";

# ------------------------------------------
# 0)  porttes-2335  =>    <idle>-0   
# ------------------------------------------
#
# 0) + 61.376 us   |    } /* __switch_to */
# 0)   0.768 us    |    rcu_needs_cpu();
# 1)   7.040 us    |                } /* faboid_fab_objget */
# 1)               |                _sys_sema_unlock() {
# 1)   0.704 us    |                  _sys_lock_debug_pre_unlock();

while(my $line = <>) {
	# Get the core being used
	# 1)               |  rte_msg_handle() {
	next unless ($line =~ /^\s*(\d+)\)/);
	$core = $1;
	chomp($line);

	# Search for the process that is starting on this core
	# 0)    sh-5257     =>    <idle>-0

	if ($line =~ /\s+=>\s+(.*)-(\d+)/) {
		$process[$core] = $1;
		$pid[$core] = $2;
		$ProcessName{$pid[$core]} = $process[$core];
		$FC[$core] = "FuncCount" . $pid[$core];
		$TC[$core] = "Time" . $pid[$core];
		print "$line: c($core) p($p) name($ProcessName{$pid[$core]}) pid($pid[$core]) $nFuncCount $nTime\n" if $debug;
		next;
	}

	if ($line =~ /=>/) {
		die $line;
	}

	$PerPidTrace{$ProcessName{$pid[$core]}} .= $line . "\n";

	$nFuncCount = $FC[$core];
	$nTime = $TC[$core];
	
	my @s = split(/\|/,$line);
	$s[1] =~ /^(\s+)/;
	my $indc = length($1);
	my $dur = time_from_str($s[0]);
	1 while ($s[1] =~ s/\s+//g);
	$s[1] =~ /(\w+)/;
	my $func = $1;

	if ($s[1] =~ /}/) {
		$$nTime{$IndFunc[$pid[$core]][$indc]} += $dur;
		#$$nTime{_Total_} += $dur;
	} elsif ($s[1] =~ /;/) {
		$$nTime{$func} += $dur;
		$$nFuncCount{$func} ++;
		#$$nFuncCount{_Total_} ++;
	} else {
		$$nFuncCount{$func} ++;
	}

	printf "proc:%10s pid=%5d core:%d dur:%6.3f indc=%3d (%50s) f(%50s)=%-4d m(%6.3f) %s\n",
			$ProcessName{$pid[$core]}, $pid[$core], $core, $dur, $indc, $func, $IndFunc[$pid[$core]][$indc],
			$$nFuncCount{$func}, $$nTime{$IndFunc[$pid[$core]][$indc]}, $nFuncCount if $debug;

	
	#Find matching "}"
	$IndFunc[$pid[$core]][$indc] = $func;
}



#Print out the top calls
for my $pid (sort keys %ProcessName) {
	$nFuncCount = "FuncCount" . $pid;
	$nTime = "Time" . $pid;

	printf "Highest average per call for %s pid($pid) nF($nFuncCount) nT($nTime):\n", $ProcessName{$pid};
	$to_print = 40;
	for $k (sort by_calls keys(%$nFuncCount)) {
		next unless length($k);
		printf "%50s : %6d %12.3f\n", $k, $$nFuncCount{$k}, $$nTime{$k} if $to_print-- > 0;
	}

	printf "Most time for %s pid($pid):\n", $ProcessName{$pid};
	$to_print = 40;
	for $k (sort {$$nTime{$b} <=> $$nTime{$a}} keys(%$nTime)) {
		next unless length($k);
		printf "%50s : %6d %12.3f\n", $k, $$nFuncCount{$k}, $$nTime{$k} if $to_print-- > 0;
	}
}



#Print out the per process call graph
for my $pid (sort keys %ProcessName) {
	$pidn = $ProcessName{$pid};
	print "-" x 80 . "\n$pidn($pid)\n" . "-" x 80 . "\n";
	print $PerPidTrace{$pidn} . "\n" . "-" x 80 . "\n";
}




#######################################
sub time_from_str() {
	my $timestr = shift;
	my @s = split(/\s/,$timestr);
	pop(@s);
	return (pop(@s));
}

sub by_calls() {
	($$nTime{$b}/$$nFuncCount{$b}) <=> ($$nTime{$a}/$$nFuncCount{$a});
}
