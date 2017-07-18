#!/usr/local/bin/perl
sub show_help() {
	($program) = $0 =~ /.*\/(.*)$/;
	print "$program <CFG FILE> [-p<ext>,<int>,<lossless>,<dls>]\n";
	#print "$program rand <count> - run random regression test\n";
	#print "$program ti           - run TI test\n";
	exit;
}

my $nextarg = "";
foreach my $arg (@ARGV) {
	if ($nextarg eq "cfg") { $nextarg = ""; $arg = "-c" . $arg; print STDERR "changed ($arg)\n"};
	if ($arg =~ /^-/) {
		if    ($arg =~ /^-h/i) { show_help(); }
		elsif ($arg =~ /^-f(\d+)/i) { push(@Fs, substr($arg,2)) }
		elsif ($arg =~ /^-e(\d+)/i) { push(@Es, substr($arg,2)) }
		elsif ($arg =~ /^-d(\d+)/i) { $Doms = substr($arg,2) }
		elsif ($arg =~ /^-t(\d+)/i) { $TIs = substr($arg,2) }
		elsif ($arg =~ /^-foe(\d+)/i) { $TIfo = 1 }
		elsif ($arg =~ /^-fod(\d+)/i) { $TIfo = 0 }
		elsif ($arg =~ /^-c(.+)/) { my $cfg = substr($arg,2); push(@CFGs, $cfg) if -r $cfg; }
		elsif ($arg =~ /^-c$/) { $nextarg = "cfg"; print STDERR "next is cfg ($arg)\n"}
		elsif ($arg =~ /^-p(\d+),(\d+),(\d+),(\d+)/) { change_policy($1,$2,$3,$4) }
		elsif ($arg =~ /^-p(\d+),(\d+),(\d+)/) { change_policy($1,$2,$3,1) }
		elsif ($arg =~ /^-p(\d+),(\d+)$/) { change_policy($1,$2,1,1) }
		elsif ($arg =~ /^-p(\d+)$/) { change_policy($1,0,1,1) }
	} else {
		push(@CFGs, $arg) if -r $arg && $arg !~ /^\d+$/;
	}
}

if (scalar @CFGs) {
	for my $cfg (@CFGs) {
		printf STDERR "Processing config file: %s\n", $cfg;
		next unless open (CF, $cfg);
		foreach my $line (<CF>) {
			parse_line($line);
		}
	}
	unless ($Shown) {
		show_paths();
	}
	quit();
	exit();
}
my $Fs = shift @ARGV || 32;
my $Es = shift @ARGV || 32;
my $Doms = shift @ARGV || 1;
my $TIs = shift @ARGV || 0;
my $TIfo = shift @ARGV || 0;
my $EStart = 0;
my $FStart = 200;
my @E = ();

$Fs = 0 if $Fs =~ /none|zero/i;
$Es = 0 if $Es =~ /none|zero/i;
if ($Fs =~ /(\d+):(\d+)/) {
	$Fs = $1;
	$FStart = $2;
}
if ($Es =~ /(\d+):(\d+)/) {
	$Es = $1;
	$EStart = $2;
}
print STDERR "F:$Fs st=$FStart\t";
print STDERR "E:$Es st=$EStart\n";

if ($Fs =~ /\d+/) {
	change_topo();
	add_CUP() if $TIfo =~ /cup/i;
	foreach my $p ($EStart..($EStart+$Es-1)) {
		add_E($p,(($p%$Doms)+1), 8000, ($TIs > 0) ? ($p % $TIs)*2 : 0, ($TIfo =~ /d|1/) ? 1 : $TIfo);
	}
	foreach my $p ($FStart..($FStart+$Fs-1)) {
		add_F($p, 4000, ($TIs > 0) ? ($p % $TIs)*2 : 0, ($TIfo =~ /d|1/) ? 1 : $TIfo);
	}
	main();
	show_paths();
	hafailover() if $TIfo =~ /h/i;
	show_paths();
} elsif ($Fs =~ /ti/i) {
	print "14\n";
} elsif ($Fs =~ /rand/i) {
	print "13\n$Es\n";
}
if ($TIfo =~ /r/i) {
	change_topo();
	remove_ti();
	main();
	show_paths();
}
quit();


sub parse_line() {
	my $line = shift;
	$line =~ s/#.*//g; # Take out comments
	if ($line =~ /^#/) { return; }
	elsif ($line =~ /^E/) { parse_E($line); }
	elsif ($line =~ /^F/) { parse_F($line); }
	elsif ($line =~ /^cup/i) { add_CUP(); }
	elsif ($line =~ /^ha/i) { hafailover(); }
	elsif ($line =~ /^ti/i) { parse_ti($line); }
	elsif ($line =~ /^blade/i) { parse_blade($line); }
	elsif ($line =~ /^rem.*ti/i) { remove_ti(); }
	elsif ($line =~ /^show.*dom/i) { show_dom_route_info(split(/\s+/,$line)); }
	elsif ($line =~ /^show/i) { show_paths($line); }
	elsif ($line =~ /^dump/i) { dump_rte($line); }
	elsif ($line =~ /^perf/i) { show_perf($line); }
	elsif ($line =~ /^exit/i) { exit(); }
}

sub parse_E() {
	my $line = shift;
	chomp($line);
	my @s = split(/\s+/,$line);
	my @es = ();
	my @Doms = ();
	my $bw = 16000;
	my $ti = 0;
	my $fo = 0;
	my $show = 0;
	my $Efunc = "add_E";
	foreach my $j (@s) {
		push(@es, split(/,/, $j)) if $j =~ /^\d+,\d+/;
		push(@es, ($1 .. $2)) if $j =~ /^(\d+)\.\.(\d+)/;
		push(@es, $j) if $j =~ /^\d+$/;
		push(@Doms, $1) if $j =~ /^D[[:alpha:]]*(\d+)$/i;
		push(@Doms, ($1 .. $2)) if $j =~ /^D[[:alpha:]]*(\d+)\.\.(\d+)/i;
		$bw = $1 if $j =~ /^bw=(\d+)/i;
		$ti = $1 if $j =~ /^ti=(.*)$/i;
		$show = $j if $j =~ /^show/i;
		$Efunc = "del_E" if $j =~ /off|down|del/i;
		$Efunc = "bw_change" if $j =~ /change/i;
	}

	push(@Doms, 1) unless scalar @Doms;

	if ($ti =~ /,/) {
		($ti,$fo) = split(/,/, $ti);
		$fo = (($fo =~ /d|1/) ? 1 : $fo) 
	}
	printf STDERR "$Efunc( [@es], dom=(@Doms) bw=$bw ti=$ti fod=$fo )\n";
	foreach my $e (@es) {
		if ($Efunc =~ /bw_change/) {
			&{$Efunc}($e, $bw);
			next;
		}
		foreach my $dom (@Doms) {
			&{$Efunc}($e, $dom, $bw, $ti, $fo);
			show_paths($show) if $show =~ /all/i;
		}
	}
	if ($show) {
		show_paths($show) unless $show =~ /all/i;
	}
}

sub parse_F() {
	my $line = shift;
	chomp($line);
	my @s = split(/\s+/,$line);
	my @fs = ();
	my $bw = 4000;
	my $ti = 0;
	my $fo = 0;
	my $show = 0;
	my $Ffunc = "add_F";
	foreach my $j (@s) {
		push(@fs, split(/,/, $j)) if $j =~ /^\d+,\d+/;
		push(@fs, ($1 .. $2)) if $j =~ /^(\d+)\.\.(\d+)/;
		push(@fs, $j) if $j =~ /^\d+$/;
		$bw = $1 if $j =~ /^bw=(\d+)/i;
		$ti = $1 if $j =~ /^ti=(.*)/i;
		$show = $j if $j =~ /^show/i;
		$Ffunc = "del_F" if $j =~ /off|down|del/i;
		$Ffunc = "bw_change" if $j =~ /bw.*change/i;
	}
	if ($ti =~ /,/) {
		($ti,$fo) = split(/,/, $ti);
		$fo = (($fo =~ /d|1/) ? 1 : $fo) 
	}
	printf STDERR "$Ffunc( [@fs], bw=$bw ti=$ti fod=$fo )\n";
	foreach my $f (@fs) {
		&{$Ffunc}($f, $bw, $ti, $fo);
		show_paths($show) if $show =~ /all/i;
	}
	if ($show) {
		show_paths($show) unless $show =~ /all/i;
	}
}

sub parse_ti() {
	my $line = shift;
	chomp($line);
	my ($t, $ps, $tinum, $tifo) = split(/\s+/,$line);
	my @pts = ();

	push(@pts, split(/,/, $ps)) if $ps =~ /^\d+,\d+/;
	push(@pts, ($1 .. $2)) if $ps =~ /^(\d+)\.\.(\d+)/;
	push(@pts, $ps) if $ps =~ /^\d+$/;
	$tinum = $1 if $j =~ /^ti=(.*)/i;
	$tinum = $j if $j =~ /^\d+$/;
	if ($tinum =~ /,/) {
		($tinum,$tifo) = split(/,/, $tinum);
	}
	$tifo = (($tifo =~ /d|1/) ? 1 : $tifo);
	printf STDERR "Update TI ([@pts], tinum=$tinum, tifo=$tifo)\n";
	foreach my $p (@pts) {
		update_ti($p, $tinum, $tifo);
	}
}

sub parse_blade() {
	my $line = shift;
	my $cmd = "501";
	my $cname = "<?>";

	chomp($line);
	my ($t, @s) = split(/\s+/,$line);
	foreach my $b (@s) {
#	Blade event options:
		$cmd = "500" if $b =~ /^cr/i;  # 500. Blade Create
		$cmd = "501" if $b =~ /^del/i; # 501. Blade Delete
		$cmd = "502" if $b =~ /^on/i;  # 502. Blade Online
		$cmd = "503" if $b =~ /^off/i; # 503. Blade Offline
		$cmd = "504" if $b =~ /^en/i;  # 504. Blade Enable
		$cmd = "505" if $b =~ /^dis/i; # 505. Blade Disable
		$cname = $b if $b =~ /^cr|^del|^on|^off|^en\|^dis/i;

		$slot = $b if $b =~ /^\d+$/;
	}
	printf STDERR "Blade cmd=[$cname]($cmd) slot=($slot)\n";
	blade_cmd($cmd,$slot);
}


sub change_topo() { if ($Menu ne "Topo") { print "11\n"; $Menu = "Topo"; } }
sub main() { if ($Menu eq "Topo") { print "0\n"; $Menu = "Main"; } }
sub add_E() { my ($port, $dom, $bw, $ti, $fo) = @_; change_topo(); print "3\n$port,$dom\n"; unless($E[$port]++) { print "$bw,$ti,$fo\n"; } }
sub del_E() { my ($port, $dom) = @_; change_topo(); if ($E[$port]) { print "4\n$port,$dom\n"; $E[$port]--; } }
sub add_F() { my ($port, $bw, $ti, $fo) = @_; unless($E[$port]) { change_topo(); print "1\n$port,$bw,$ti,$fo\n"; } }
sub del_F() { my ($port) = @_; unless($E[$port]) { change_topo(); print "2\n$port\n";} }
sub add_CUP() { change_topo(); print "6\n1\n254\n"; }
sub show_dom_route_info() { my $dom = pop; change_topo(); print "8\n$dom\n"; }
sub change_policy() { my $ext = shift || 3; my $int = shift; my $loss = shift; my $dls = shift; change_topo(); print "10\n$ext,$int,$loss,$dls\n"; }
sub blade_cmd() { my $cmd = shift || 501; my $blade = shift || 0; main(); print "5\n$cmd\n$blade\n"; }
sub bw_change() { my ($port, $bw) = @_; change_topo(); print "5\n$port,$bw\n"; }
sub show_edges() { show_paths("edges"); }
sub remove_ti() { print STDERR "Remove All TI zones\n"; update_ti(-1,0,1); }
sub update_ti() { my ($port, $tinum, $tifo) = @_; change_topo(); printf "9\n%d,%s,%d\n", $port, $tinum, ($tifo) ? 0 : 1; }
sub hafailover() { print STDERR "HA Failover...\n"; main(); print "9\n2\n" }
sub quit() { print "0\n0\n0\n0\n0\n0\n"; }
sub show_paths() {
	my ($type,$rg) = split(/\s+/, join(' ', @_));
	$rg = int($rg);
	print STDERR "show_paths: type($type) rg($rg)\n";
	my $d = ($type =~ /d/) ? "8" : "6";
	my $e = ($type =~ /edge/) ? "$rg,1" : ($d eq "8") ? "$rg,0" : "$rg";
	main();
	print "2\n$d\n$e\n0\n";
	$Shown++;
}
sub dump_rte() { main(); print "2\n21\n0\n"; $Shown++ }
sub show_perf() {
	my $line = shift;
	my $perfc = "15"; # show
	if ($line =~ /clear|reset/i) {
		$perfc = "16";
	}
	main();
	print "2\n$perfc\n"
}
