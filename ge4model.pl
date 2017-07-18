#!/usr/local/bin/perl
die "Usage: $0 [testname] [regdump] [rx chip port] [DID] [SID] [OXID] [SOF] [Frame Length] [vc] [grep pattern]\n" if scalar @ARGV < 2;

my $name = shift || $ENV{USER};
my $regdump = shift || "regdump.dmp";
my $port = shift || 0;
my $did = shift || "0x481400";
my $sid = shift || "0x470300";
my $oxid = shift || 0;
$oxid = hex($oxid) if $oxid =~ /^0x/;
my $sof = shift || 3;
my $flen = shift || 160;
my $vc = shift || 0;
my $grep = shift || "";

$did = hex($did);
$sid = hex($sid);
#my $base = "/proj/tatooine/condor4/condor4RM/condorRM/";
#my $base = "/users/home55/pcieslar/dev/GE4RM/";
my $base = "/proj/tatooine/geye4/GE4RM/";
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
print "grep($grep)\n" if $grep;

#ASIC C-model simulator will be used to run on the Cobra regdump to help tracing register configuration problems.

#Instructions: (Please replace N with A or B based on the cobra revision.)

#1.  Generate a frame file based on actual frame format. If you are not sure about the specifics of an FC frame, you can use XGIG analyzer to capture one or copy 
#    my frame from"/proj/sj_eng/Projects/cob ra_fc/cobraRM2012_10_08/tests/mytest/mytest.in.
#2.  Go to"/proj/sj_eng/Projects/cobra_fc/cobraNRM" and mkdir your directory "xyz". Copy your frame into"/proj/sj_eng/Projects/cobra_fc/cobraNRM/tests/xyz/xyz.in".
#3.  Do a "regdump 0/0" on Castor. Copy the /var/regdump.dmp to your linux directory.
#4.  Decode the regdump by  "/proj/sj_eng/Projects/cobra_fc/cobraNRM/regdec_cbr_N.host regdump.dmp > cobra_reg.txt"
#5.  Convert the reg format by "sed '/^0x/! d' cobra_reg.txt |tr -d ':'|cut -d " " -f 1,3 > /proj/sj_eng/Projects/cobra_fc/cobraNRM/tests/xyz/xyz.reg"
#Go to"/proj/sj_eng/Projects/cobra_fc/cobraNRM"" and run "testswlib -t xyz -b ref -d 3 |tee tests/xyz/xyz.log"
system("mkdir $base/tests/$name") unless -e "$base/tests/$name";
$cmd = ($regdump =~ /gz$/) ? "zcat" : "cat";
#system("$cmd $regdump | sed '/^0x/! d' | tr -d ':'|cut -d' ' -f 1,3 > $base/tests/$name/$name.reg");

if (open(IN_REGS, "$cmd $regdump |")) {
	open(OUT_REGS, ">$base/tests/$name/$name.reg") || die "Could not write reg file to $base\n";
	while (my $line = <IN_REGS>) {
		if ($line =~ /^0x\w{8}:\s+/) {
			my ($addr, $val, @s) = split(/\s+/,$line);
			chop($addr);
			print OUT_REGS "$addr $val //@s\n";
			print "$addr $val //@s\n" if $pv++ < 20;
		}
	}
	close(OUT_REGS);
	close(IN_REGS);
} else {
	print "Could not $cmd $regdump\n";
	exit();
}


if (open(FRAME, ">$base/tests/$name/$name.in")) {
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
	printf FRAME "vc: %d\n", $vc if $vc;

	close FRAME;
}
system("cat $base/tests/$name/$name.in");
my $testcmd = "cd $base/; ./testrmlib -t $name -b ref -d 3";
print $testcmd . "\n";
system ("$testcmd > tests/$name/$name.$ds.log");
print "Log: $base/tests/$name/$name.$ds.log\n";

if ($grep) {
	print `grep $grep $base/tests/$name/$name.$ds.log`;
}

