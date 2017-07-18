#!/usr/local/bin/perl

$| = 1;

my $IPstring = shift || ("10.38.17.102");
my @IPs = split(/,/, $IPstring);
my $Mod = shift || 144;
my $Time = shift || 5;
my $Loops = shift || 1_000_000_000;
my $Size = shift || 500;


print "$IPstring (@IPs) Module=$Mod Time=$Time Loops=$Loops Size=$Size\n";

foreach my $ip (@IPs) { $LastTime{$ip} = "Fri,Jan,1,000000.00000,1900"; }

while($count++ < $Loops) {

	foreach my $ipr (@IPs) {
		my ($ip,$lc,$mod) = split(/:/,$ipr);
		my $rcli = "rcli -s $lc" if $lc ne "";
		$mod = $Mod unless $mod;
		my $size = ($rcli) ? 20 : $Size;
		print "ip($ip) rcli($rcli) mod($mod) size($size)\n" if $debug;

		my @rasdecode = `switchssh $ip "$rcli rasdecode -v -m $mod -n $size"`;
		foreach my $line (@rasdecode) {
			my $key = substr($line,0,80);
			my @s = split(/\s+/,$key,6);
			if (newer_timestamp($ip, @s)) {
				print "$ip:" if scalar @IPs > 1;
				print $line;
			}
			$total++;
		}
	}
	print ".";
	sleep($Time);
}
print "\nLogged: " . scalar(keys(%Logged)) . " Count=$count Total=$total\n";
exit();


sub newer_timestamp() {
	my $ip = shift;
	my @s = ($_[0], $_[1], $_[2], $_[3], $_[4]);

	return 0 unless $s[3] =~ /\d{2}:\d{2}:\d{2}\.\d+/;

	my @l = split(/,/,$LastTime{$ip});
	my %Mon = ( Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6, Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12 );

	my $hms = $s[3];
	my $lhms = $l[3];
	$hms =~ s/://g;
	$hms = sprintf("%6.5f", $hms);

	$lhms = $hms unless $lhms =~ /\./;
	my ($i,$d) = split(/\./, $hms);
	my ($li,$ld) = split(/\./, $lhms);

	# Assume date string like: "Fri Jun  5 13:37:17.098506 2009"
	my $newer = 0;

	$s[3] = $hms;
	my $ts = join(',', @s);
	my $compare = ($s[4] <=> $l[4]) || ($Mon{$s[1]} <=> $Mon{$l[1]}) || ($s[2] <=> $l[2]) || (int($i) <=> int($li)) || (int($d) <=> int($ld));
	#if ((int($i) > int($li)) || ((int($i) == int($li)) && (int($d) >= int($ld))))
    if ($compare > 0) {
		printf "\tlast[%s] y%s m%s(%s) d%s h%d u%d $compare\n", $LastTime{$ip}, $l[4], $l[1], $Mon{$l[1]}, $l[2], $li, $ld if $debug;
		printf "\tNEW [%s] y%s m%s(%s) d%s h%d u%d\n", $ts, $s[4], $s[1], $Mon{$s[1]}, $s[2], $i, $d if $debug;
		$LastTime{$ip} = $ts;
		$newer = 1;
	} else {
		printf "\tLAST[%s] y%s m%s(%s) d%s h%d u%d $compare\n", $LastTime{$ip}, $l[4], $l[1], $Mon{$l[1]}, $l[2], $li, $ld if $debug;
		printf "\told [%s] y%s m%s(%s) d%s h%d u%d\n", $ts, $s[4], $s[1], $Mon{$s[1]}, $s[2], $i, $d if $debug;
		$newer = 0;
	}

	return $newer;
}




# this apprach does not work since the timestamps can be off by +/- a few usec
while($count++ < $Loops) {

	foreach my $ip (@IPs) {
		my @rasdecode = `switchssh $ip "rasdecode -v -m $Mod -n $Size"`;
		foreach my $line (@rasdecode) {
			my $key = substr($line,0,80);
			my @s = split(/\s+/,$key,5);
			my $ts = $s[3];
			$ts =~ s/://g;
			my ($i,$d) = split(/\./,$ts);

			$key = join('', $s[0], $s[1], $s[2], $i, $d, $s[4]);

			$key =~ s/\W+//g;

			unless ($Logged{$key}) {
				print "$ip:" if scalar @IPs > 1;
				print $line;
			}

			$Logged{$key}++;
			$Logged{$keyh}++;
			$Logged{$keyl}++;
			$total++;
		}
	}
	print ".";
	sleep($Time);
}
