#!/usr/local/bin/perl
%tnums = ();

my $input = shift || "no input";
my @Hosts = ();
my @Targets = ();

if ($input =~ /no input/) {
	@Hosts = (
	"st45H,10:00:8c:7c:ff:5c:cd:01,lsan",
	"c51fcH,10:00:8c:7c:ff:5d:0d:00",
	#"c51fcoeH,10:00:00:05:1e:f4:3c:0f",
	"c52fcH,10:00:8c:7c:ff:5d:0d:01",
	"c52fcoeH,10:00:00:05:1e:f4:3c:0f",
	);

	@Targets = (
	"st47,20:04:00:11:0d:5b:00:00,lsan",
	"c51fcT,20:07:00:11:0d:93:01:00",
	"c51fcoeT,20:05:00:11:0d:d5:28:00",
	"c52fcT,20:06:00:11:0d:93:00:00",
	"c52fcoeT,20:07:00:11:0d:a5:f1:00",
	);
} else {
	if (-e $input) {
		open(INP, $input) || die;
		while (my $line = <INP>) {
			print $line;
		}
	}
	exit();
}

my @zones = ();
my @lsans = ();

foreach my $h (@Hosts) {
	my ($hpre,$hwwn,$hlsan) = split(/,/,$h);
	print "hpre[$hpre] hwwn[$hwwn] hlsan[$hlsan]\n" if $debug;
	foreach my $t (@Targets) {
		my ($tpre,$twwn,$tlsan) = split(/,/,$t);
		$twwn = wwn_add_num($twwn);
		print "tpre[$tpre] twwn[$twwn] tlsan[$tlsan]\n" if $debug;
		my $lsan = "lsan_" if ($hlsan || $tlsan);
		my $zonename = sprintf("%s%s_%s", $lsan, $hpre, $tpre);
		print "zonename[$zonename]\n" if $debug;
		printf "zonecreate %s, \"%s;%s\"\n", $zonename, $hwwn, $twwn;
		push(@zones, $zonename);
		push(@lsans, $zonename) if $zonename =~ /lsan/;
	}
}

foreach my $z (@zones) {
	print "zonedelete $z\n";
}
my $zl = join(';',@zones);
printf "cfgcreate traffic, \"%s\"\n", $zl;

my $lsz = join(';',@lsans);
printf "cfgcreate lsan_traffic, \"%s\"\n", $lsz;



sub wwn_add_num() {
	my $wwn = shift;
	my $num = 0;
	if (defined($tnums{$wwn})) {
		$num = $tnums{$wwn};
		$tnums{$wwn} = $num + 1;
	} else {
		$tnums{$wwn} = 1;
	}

    my @n = split(/:/,$wwn);
	$n[-1] = sprintf("%02x", $num);
	return (join(":", @n));
}
