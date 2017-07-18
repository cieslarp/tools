#!/usr/local/bin/perl

my $name =  $ENV{USER};
my $regdump =  "regdump.dmp";
my $port =  62;
my $did =  "0x481400";
my $sid =  "0x470300";
my $oxid =  0;
$oxid = hex($oxid) if $oxid =~ /^0x/;
my $sof =  3;
my $flen =  160;
my $grep =  "";
my $reduce_regs =  0;
my $seed = "";
my $VC = 0;

foreach my $arg (@ARGV) {
	if ($arg =~ /^-(\w)(\w*)$/) {
		my $c = $1;
		my $v = $2;
		$name = $v if $c =~ /^n/;
		$port = $v if $c =~ /^p/;
		$did  = $v if $c =~ /^d/;
		$sid  = $v if $c =~ /^s/;
		$oxid = $v if $c =~ /^x/;
		$seed = $v if $c =~ /^S/;
		$sof  = $v if $c =~ /^f/;
		$flen = $v if $c =~ /^z/;
		$grep = $v if $c =~ /^g/;
		$VC   = $v if $c =~ /^v/;
		$reduce_regs = 1 if $c =~ /^r/;
	} else {
		$regdump = $arg;
	}
}

$did = hex($did);
$sid = hex($sid);
#my $base = "/proj/tatooine/condor4/condor4RM/condorRM/";
my $base = "/users/home55/pcieslar/dev/condorRM";
if ($0 =~ /c4p/) {
	$base = "/users/home55/pcieslar/dev/condor4plus_RefModel_2016_05_16";
}
#/proj/tatooine/condor4/condor4RM/condorRM/tests/rmlib/ftb/ftb.in
my $ds = $$;
print "name($name)\n";
print "base($base)\n";
print "regd($regdump)\n";
print "port($port)\n";
print " sof($sof)\n";
printf " did($did)%x\n",$did;
printf " sid($sid)%x\n",$sid;
printf "oxid($oxid)%x\n",$oxid;
print "flen($flen)\n";
print "VC($VC)\n";
print "grep($grep)\n" if length($grep);
print "seed($seed)\n" if length($seed);
print "reduce_regs($reduce_regs)\n" if $reduce_regs;

if (! -e $regdump) {
	my @s = split(/\//,$0);
	my $basecmd = pop(@s);
	print "Usage: $basecmd -n<name> -p<port> -d<did> -s<sid> -x<oxid> -S<seed> -f<sof> -z<flen> -g<grep> -v<VC> -r[reduce regs=1]\n";
	exit();
}
#ASIC C-model simulator will be used to run on the Cobra regdump to help tracing register configuration problems.

#Instructions: (Please replace N with A or B based on the cobra revision.)

#1.  Generate a frame file based on actual frame format. If you are not sure about the specifics of an FC frame, you can use XGIG analyzer to capture one or copy 
#    my frame from"/proj/sj_eng/Projects/cob ra_fc/cobraRM2012_10_08/tests/mytest/mytest.in.
#2.  Go to"/proj/sj_eng/Projects/cobra_fc/cobraNRM" and mkdir your directory "xyz". Copy your frame into"/proj/sj_eng/Projects/cobra_fc/cobraNRM/tests/xyz/xyz.in".
#3.  Do a "regdump 0/0" on Castor. Copy the /var/regdump.dmp to your linux directory.
#4.  Decode the regdump by  "/proj/sj_eng/Projects/cobra_fc/cobraNRM/regdec_cbr_N.host regdump.dmp > cobra_reg.txt"
#5.  Convert the reg format by "sed '/^0x/! d' cobra_reg.txt |tr -d ':'|cut -d " " -f 1,3 > /proj/sj_eng/Projects/cobra_fc/cobraNRM/tests/xyz/xyz.reg"
#Go to"/proj/sj_eng/Projects/cobra_fc/cobraNRM"" and run "testswlib -t xyz -b ref -d 3 |tee tests/xyz/xyz.log"
system("mkdir $base/tests/rmlib/$name") unless -e "$base/tests/rmlib/$name";
$cmd = ($regdump =~ /gz$/) ? "zcat" : "cat";
#system("$cmd $regdump | sed '/^0x/! d' | tr -d ':'|cut -d' ' -f 1,3 > $base/tests/rmlib/$name/$name.reg");

if (open(IN_REGS, "$cmd $regdump |")) {
	open(OUT_REGS, ">$base/tests/rmlib/$name/$name.reg") || die "Could not write reg file to $base\n";
	while (my $line = <IN_REGS>) {
		if ($reduce_regs) {
			#next if $line =~ /c4_lue1_flw_tbl/; : 2097152
			next if $line =~ /c4_lue2_flw_tbl/; # : 262144
			#next if $line =~ /c4_lue1_hsh_tbl_main/; # : 262144
			#next if $line =~ /c4_rte_egid_lkup_tbl/; # : 147456
			next if $line =~ /c4_lue2_hsh_tbl/; # : 131072
			next if $line =~ /ios_flw_sts/; # : 65536
			#next if $line =~ /c4_rte_info/; # : 65536
			#next if $line =~ /c4_rte_did_lkup_tbl/; # : 65536
			next if $line =~ /c4_txq_buf_desc_ram0/; # : 61440
			next if $line =~ /c4_txq_buf_desc_ram1/; # : 61440
			#next if $line =~ /c4_fpg/; # : 35192
			#next if $line =~ /c4_phy_reg/; # : 34592
			next if $line =~ /c4_ftb_stats/; # : 32768
			next if $line =~ /c4_gflt_tcam_key/; # : 32768
			next if $line =~ /ios_flw_ext/; # : 24576
			#next if $line =~ /c4_lue1_hsh_tbl_annx/; # : 16384
			#next if $line =~ /act_lkup_tbl/; # : 16384
			next if $line =~ /c4_lnk_cam_mem/; # : 16384
			next if $line =~ /ios_flw_main/; # : 16384
			next if $line =~ /c4_txq_latency_ram/; # : 10240
		}
		if ($line =~ /^0x\w{8}:\s+/) {

			my ($addr, $val, @s) = split(/\s+/,$line);
			chop($addr);
			if ($s[0] =~ /dp_ctl/) {
				if (length($seed) > 0) {
					my $v = (hex($val) & ~0x3FF) | hex($seed);
					my $newval = sprintf("0x%08x", $v);
					printf "$addr $val //@s --> new($seed) v(%x) newval($newval)\n", $v;
					$val = $newval;
					$pv = 19;
				}
			}
			print OUT_REGS "$addr $val //@s\n";
			print "$addr $val //@s\n" if $pv++ < 20;

			if ($reduce_regs) {
				my ($regname,@a) = split(/\[|\]/,$s[0]);
				$RegCount{$regname}++;
			}

		}
	}
	close(OUT_REGS);
	close(IN_REGS);
	if ($reduce_regs) {
		my @sr = sort {$RegCount{$b} <=> $RegCount{$a}} keys %RegCount;
		print "sr: " . scalar @sr . "\n";
		for my $i (0..19) {
			printf "%30s : %d\n", $sr[$i], $RegCount{$sr[$i]};
		}
	}
} else {
	print "Could not $cmd $regdump\n";
	exit();
}


if (open(FRAME, ">$base/tests/rmlib/$name/$name.in")) {
	my @framedata = ();

	my $RCtl = (($did >> 24) & 0xff);

	if ($sof =~ /3/) {
		$RCtl = 0x22 unless $RCtl;
		push(@framedata, (0xBC,0xB5,0x56,0x56, $RCtl)); #Sofi3
	} else {
		$RCtl = 0xC0 unless $RCtl;
		push(@framedata, (0xBC,0xB5,0x58,0x58, $RCtl)); #SOFf
	}
	push(@framedata, (($did >> 16) & 0xff));
	push(@framedata, (($did >> 8) & 0xff));
	push(@framedata, (($did) & 0xff));

	push(@framedata, 0x00);
	push(@framedata, (($sid >> 16) & 0xff));
	push(@framedata, (($sid >> 8) & 0xff));
	push(@framedata, (($sid) & 0xff));

	push(@framedata, (0x08, #type
					  0x00,00,00, #ftctl
					  0x00, 0x01, 0x00,0x00)); #seq_id, df_ctl, seq_cnt
	push(@framedata, (($oxid >> 8) & 0xFF));
	push(@framedata, ($oxid & 0xFF));
	push(@framedata, (0xff,0xff)); #rxid

	#push(@framedata, (0x00) x 11);
	$svmid = 0x08;
	$dvmid = 0x00;
	push(@framedata, (0x11,0x22,0x33,0x44,0x00,0x00,0x00,0x00,0x00,0x00,0x00));
	push(@framedata, $svmid);
	push(@framedata, (0x00,0x00,0x00,$dvmid));

	for $i (0..$flen - (scalar @framedata + 5)) {
		push(@framedata,$i);
	}
	push(@framedata, (0xBC,0xB5,0x75,0x75)); # EOF

	#printf FRAME "*vc: %d\n", 2;
	printf FRAME "port: %d\n", $port;
	printf FRAME "vc: %d\n", $VC;
	printf FRAME "recalc:\n";
	for ($i = 0; $i < scalar @framedata; $i += 16) {
		printf FRAME "%5d:  ", $i;
		for ($j = 0; $j < 16 && $j+$i < scalar @framedata; $j++) {
			printf FRAME "%02x ", $framedata[$i+$j];
			printf FRAME " " if ($j % 4) == 3;
		}
		print FRAME " \\" if ($j == 16);
		print FRAME "\n";
	}
	print FRAME "\n";

	close FRAME;
}
system("cat $base/tests/rmlib/$name/$name.in");
my $testcmd = "cd $base/tests/rmlib; ./testrmlib -t $name -b ref -d 3";
print $testcmd . "\n";
system ("$testcmd > $name/$name.$ds.log");
print "Log: $base/tests/rmlib/$name/$name.$ds.log\n";

if ($grep) {
	print `grep $grep $base/tests/rmlib/$name/$name.$ds.log`;
}

