#!/usr/local/bin/perl
use POSIX qw(strftime);

$| = 1;
my $Build = shift;
my $Dist  = shift || timestr();
my $Id    = shift;
my $Debug = 1 if $Id =~ /v$/;
my $Level = shift || 1;
my $Lrex = "[" . join('|', 0..$Level) . "]";
my $makedir = "/vobs/projects/springboard/make";
if ($Dist =~ /^fabos_build$/ && $Build =~ /^\d+$/) {
	unshift(@ARGV, $Dist) ;
	$makedir = "/vobs/projects/springboard/build/swbd$Build/make";
	die "Make dir not found: $makedir\n" unless -d $makedir;
}
unshift(@ARGV, $Dist) if $Dist =~ /^build$/;

$Id = $Dist unless length $Id;
$Id = $ENV{'USER'} . "_" . $Id . "_" . timestr();

$SIG{QUIT} = $SIG{INT} = $SIG{HUP} = \&do_exit;

do_exit('skip') if $Build =~ /skip/i;

print "BD=$Build DIST=$Dist Id=$Id\n";
die "$0: <Build num> <Dist dir> <Id>\n" unless $Build && $Dist && $Id;

$Build = "" if $Build =~ /all/i;
$Build = "BD=\"$Build\"" if ($Build && $Build !~ /incr_build/i);

$Dist = $ENV{HOME} . "/builds/$Dist" unless ($Dist =~ /^\//);
#print `rm -rf $Dist` if -d $Dist;
print `mkdir $Dist` unless -d $Dist;
print $Dist . "\n";
print "Level=($Level) Lrex=($Lrex)\n"  if $Level > 1;
$Dist = `cd $Dist; pwd`;
chomp($Dist);
$do_clean_dist = "emake_wrapper clean_dist_only; " if (glob('/vobs/projects/springboard/build/*/fabos/src') && `cleartool pwv` =~ /nos/);
print "glob(" . glob('/vobs/projects/springboard/build/*/fabos/src') . ")\n";
print $do_clean_dist . "\n";
$build = "(cd $makedir; $do_clean_dist emake_wrapper $Build DISTDIR=$Dist FABOSRELEASEID=$Id @ARGV)";

print $build . "\n";
open(BUILD, "$build |") || die;
open(OUT, ">$Dist/$Id.log") || die;
$start = time;
print OUT `date`;
print OUT "em: $build\n";
print OUT "view: " . `cleartool pwv`;
while ($line = <BUILD>) {
	print OUT $line;
	print $line if $Debug;
	print timestr() . ": " . $line if ($line =~ /Finished build:/) || 
	                 ($line =~ /swbd[0-9]+: /) ||
				     ($line =~ /Extracting\s+\w/) ||
				     ($line =~ /: error: /) ||
				     ($line =~ /Stop\.$/) ||
					 #($print_next) || (($print_next) = $line =~ /(^\/vobs.*): In function /) ||
				     ($line =~ /make\[$Lrex\]/);
}
close(BUILD);
do_exit('done');

sub do_exit() {
	my $status = shift;
	if ($status !~ /skip/) {
		close(BUILD);
		$end = time;
		my $duration = ($end-$start);
		$status = "too short" if ($duration < 300);
		$status = "build only" if ($Build =~ /build$/);
		$status = "dist only" if ($Build =~ /^dist$/);
		print OUT "Build Time = " . $duration . "\n";
		print OUT `date`;
		close(OUT);
		print "Build Time = " . $duration . "\n";
		system("gzip $Dist/$Id.log");
		system("rm -f /vobs/projects/springboard/make/history.current");
		print "Logfile = $Dist/$Id.log.gz\n";
		my @SWBDs = glob("$Dist/SWBD*");
		if (scalar @SWBDs) {
			print join("\n",@SWBDs) . "\n";
			$Latest = $ENV{HOME} . "/builds/LATEST";
			system("rm $Latest");
			system("ln -sf $Dist $Latest");
		} else {
			$status = "no SWBD";
		}
	}
	print $status . "\n";
	if ($status =~ /done|skip/) {
		my $csb = $ENV{CSCOPE_DB};
		my $csf = $ENV{CSCOPE_DB};
		my @dcsb = split(/\//,$csb);
		my $shcsb = "/dev/shm/" . $dcsb[-1];
		my $tcsb = "/scratch/fos-brm/pcieslar/cscope/" . $dcsb[-1];
		$csf =~ s/\.out/.files/g;
		if (-l $csb) {
			print timestr() . ": Remove linked csb $csb\n";
			print `rm $csb` 
		}

		print timestr() . ": Create allfiles.pl search index...\n";
		system("allfiles.pl");
		print timestr() . ": Create cscope db ($csb)\n";
		system("cscope -i$csf -f$tcsb -b");
		`cp $tcsb $shcsb`;
		my $cmp = (`cmp $tcsb $shcsb`);
		if ($?) {
			print timestr() . ": Failed to copy $tcsb to $shcsb!\n";
			print "?($?) cmp($cmp)\n";
			system("ls -la $tcsb");
			system("ls -la $shcsb");
			`rm $shcsb`;
		} else {
			print timestr() . ": Copied $csb to $shcsb\n";
			`ln -sf $shcsb $csb`;
			system("ls -la $csb");
			system("ls -la $tcsb");
			system("ls -la $shcsb");

		}
		#system("link_cscope /vobs/projects/springboard/fabos/cscope.out");
	}
	exit();
}

sub timestr() {
	return strftime "%d%b%Y_%H%M%S", localtime;
}
