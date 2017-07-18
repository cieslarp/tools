#!/usr/local/bin/perl

$Date = shift || "131022_2000";
$Branch = shift || "nos_taurus_tor_ha_dev";
$MyBranch = shift || `cleartool catcs | grep -e "^mkbranch" | tail -1 | cut -f2 -d" "`;
$no_zero_merge = shift;
chomp($MyBranch);

print STDERR "Merge to $Branch as of $Date to $MyBranch\n";
#print `refresh_view -rci`;
my $from_view = "fabos_p_Nightly_" . $Branch . "_" . $Date;
my $from_branch_elem = `cleartool catcs -tag $from_view | grep $Branch...c`;
my $from_time = $1 if ($from_branch_elem =~ /since\((.*)\)\&/);
my @utcts = `/usr/rational/local/bin/localTimeConverter.pl -time $from_time`;
my $from_utc_time = pop(@utcts);
chomp($from_utc_time);
my @curcs = `cleartool catcs`;
my @newcs = ();
my $changed_cs = 0;
my $fver = "-ftag fabos_p_Nightly_$Branch" . "_" . $Date;;
unless ($Date =~ /k/i) {
	foreach my $line (@curcs) {
		# Looking for "nos_taurus_tor_ha_dev/{!created_since(23-Oct-2013.19:52:15)"
		if ($line =~ /$Branch\/\{\!created_since/) {
			print STDERR "Old: $line";
			$line =~ s/created_since\(.*\)\&/created_since\($from_utc_time\)&/;
			print STDERR "New: $line";
			$changed_cs = 1;
		}
		push(@newcs,$line)
	}
	if ($changed_cs) {
		my $tmp_cs = "/tmp/$Branch_$Date.cs";
		open(NCS, ">$tmp_cs") || die "Cound not create: $tmp_cs\n";
		print NCS @newcs;
		close NCS;
		print STDERR `cleartool setcs $tmp_cs`;
		print STDERR "Changed config spec\n";
	}
} else {
	$fver = "-fver .../$Branch/LATEST";
}
my $cur_branch_elem = `cleartool catcs | grep $Branch...c`;
print STDERR "from_view           :  $from_view\n";
print STDERR "from_branch_elem    :  $from_branch_elem";
print STDERR "from_time           :  $from_time\n";
print STDERR "from_UTC_time       :  $from_utc_time\n";
print STDERR "current_branch_elem :  $cur_branch_elem";
unless ($Date =~ /k/i) {
	die "Current view does not have the matching timestamp! Should be: $from_utc_time\n" unless ($cur_branch_elem =~ /$from_utc_time/);
}
$fl_cmd = "cleartool find -avob -branch \'brtype($MyBranch)\' -print | cut -d@ -f1";
print STDERR "$fl_cmd\n";
#for my $file (`$fl_cmd`) {
open(FILELIST, "$fl_cmd |") || die "Could not open '$fl_cmd |' \n";
while ($file = <FILELIST>) {
	my $skip_zero = 0;
	chomp($file);
	my $Type = (-d $file) ? "d" : "f";
	if ($no_zero_merge) {
		if ($Type eq "f") {
			my $ccfile = `cleartool ls -s $file`;
			chomp($ccfile);
			if (($ccfile !~ /$MyBranch/) or ($ccfile =~ /$MyBranch\/0/)) {
				print STDERR "zero: $ccfile\n";
				my @lsh = `cleartool lshistory -bra $MyBranch -l $file`;
				print STDERR @lsh;
				print STDERR "\n";
				my $name = "n";
				my $view = "v";
				foreach my $line (@lsh) {
					if ($line =~ /^\d/) {
						my @s = split(/\s+/,$line);
						$name = $s[1] . " " . $s[2];
					} elsif ($line =~ /^\s+by view:\s(.*)\s+/) {
						$view = $1;
					} elsif ($line =~ /create branch/) {
						my $zf = $file;
						if ($view eq "v") {
							$zf = $name . " : " . $file;
							$skip_zero = 1;
							push(@zeros,$file);
						}
						$Views{$view} .= "$zf,";
					}
				}
			}
			if ($skip_zero == 0) {
				push(@files_to_merge, $file);
			}
		} else {
			push(@dirs_to_merge, $file);
		}
	}
	if ($skip_zero == 0) {
		$merge_cmd = "cleartool findmerge $file -type $Type $fver -c \"rebase from $Branch $Date\" -merge -gmerge";
		print "$merge_cmd\n";
		#print `$merge_cmd`;
	}
}

if (scalar @dirs_to_merge) {
	print "Need to merge " . scalar @dirs_to_merge . " dirs\n";
	$merge_cmd = "cleartool findmerge @dirs_to_merge -type d $fver -c \"rebase from $Branch $Date\"";
	print `$merge_cmd -print`;
}

if (scalar @files_to_merge) {
	print "Need to merge " . scalar @files_to_merge . " files\n";
	$merge_cmd = "cleartool findmerge @files_to_merge -type f $fver -c \"rebase from $Branch $Date\"";
	print `$merge_cmd -print`;
}

if (@zeros) {
	printf "Zero files: %d\n", scalar @zeros ;
	$merge_cmd = "cleartool findmerge @zeros -type f $fver -c \"rebase from $Branch $Date\"";
	print `$merge_cmd -print`;

	for my $zf (@zeros) {
		print $zf . "\n";
	}

	foreach my $k (keys(%Views)) {
		print $k . ":\n";
		my @fl = split(/,/,$Views{$k});
		foreach my $f (@fl) {
			print $f . "\n";
		}
		print "\n";
	}
}
