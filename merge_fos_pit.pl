#!/usr/local/bin/perl
print "@ARGV\n";
$Date = shift || "160602_0400";
$Branch = shift || "v8.1.0_pit_a";
$MyBranch = shift || `cleartool catcs | grep -e "^mkbranch" | tail -1 | cut -f2 -d" "`;
chomp($MyBranch);
my $view_prefix = shift || "swrel_::_fullfvt"; #my $view_prefix = "fabos_p_Nightly_";
my $fvt_string = "";
($view_prefix, $fvt_string) = split(/::/,$view_prefix,2);
$fvt_string = "_" . $fvt_string unless ($fvt_string =~ /^_./);
$fvt_string .= "_" unless ($fvt_string =~ /_$/);
$no_zero_merge = shift || 1;
my $Label = shift || "V8.0.1_GA"; # should get this from_view config spec

print STDERR "Merge to $Branch as of $Date to $MyBranch\n";
#print `refresh_view -rci`;
my $from_view = $view_prefix . $Branch . $fvt_string . $Date;
my $from_branch_elem = `cleartool catcs -tag $from_view | grep $Branch...c`;
my $from_time = $1 if ($from_branch_elem =~ /since\((.*)\)\&/);
my @utcts = `/usr/rational/local/bin/localTimeConverter.pl -time $from_time`;
my $from_utc_time = pop(@utcts);
chomp($from_utc_time);
my @curcs = `cleartool catcs`;
my @newcs = ();
my $changed_cs = 0;
my $fver = "-ftag $view_prefix$Branch" . $fvt_string . $Date;;
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
chomp($cur_branch_elem);
print STDERR "from_view           :  $from_view\n";
print STDERR "from_branch_elem    :  $from_branch_elem";
print STDERR "from_time           :  $from_time\n";
print STDERR "from_UTC_time       :  $from_utc_time\n";
print STDERR "current_branch_elem :  $cur_branch_elem\n";
print STDERR "Branch              :  $Branch\n";
print STDERR "Label               :  $Label\n";

my $label_check = `cleartool catcs | grep $Label`;
die "$Label not found in current config spec, need to use cleartool edcs to change the 'element * <Label>'\n" unless $label_check =~ /$Label/;
unless ($Date =~ /k/i) {
	die "Current view does not have the matching timestamp! Should be: $from_utc_time\n" unless ($cur_branch_elem =~ /$from_utc_time/);
}

$fl_cmd = "cleartool find -avob -branch \'brtype($MyBranch)\' -print | cut -d@ -f1";
if ($MyBranch =~ /fos_usf_chewbacca/) {
	#Need to also look for files that were just branched to fos_chewbacca_dev, but not usf yet
	$fl_cmd .= "; cleartool find -avob -branch \'brtype(fos_chewbacca_dev)\' -print | cut -d@ -f1";
}

print STDERR "$fl_cmd\n";
#for my $file (`$fl_cmd`) {
open(FILELIST, "$fl_cmd |") || die "Could not open '$fl_cmd |' \n";
while ($file = <FILELIST>) {
	next if $Processed{$file};
	$Processed{$file}++;
	next if $file =~ /lost\+found/;
	chomp($file);
	my $Type = (-d $file) ? "d" : "f";
	if ($no_zero_merge) {
		if ($Type eq "f") {
			my $ccfile = `cleartool ls $file`;
			if ($ccfile =~ /mkbranch/ && $ccfile !~ /\/fos_chewbacca_dev/) {
				push(@zeros, $file);
			} else {
				push(@files_to_merge, $file);
			}
		} else {
			$dirs_to_merge{$file}++;
		}
	} else {
		$merge_cmd = "cleartool findmerge $file -type $Type $fver -c \"rebase from $Branch $Label\" -merge -gmerge";
		print "$merge_cmd\n";
		#print `$merge_cmd`;
	}
}

if (scalar keys %dirs_to_merge) {
	my @dirs = sort keys %dirs_to_merge;
	print STDERR "#Need to merge " . scalar @dirs . " dirs\n";
	print "#Dirs to merge " . scalar @dirs . "\n";
	foreach my $d (@dirs) {
		$merge_cmd = "cleartool findmerge $d -type d $fver -c \"rebase from $Branch $Label\" -merge -gmerge";
		print "$merge_cmd\n";
		#print `$merge_cmd`;
	}
}

if (scalar @files_to_merge) {
	print STDERR "#Need to merge " . scalar @files_to_merge . " files\n";
	print "\n#Files to merge " . scalar @files_to_merge . "\n";
	foreach my $f (@files_to_merge) {
		$merge_cmd = "cleartool findmerge $f -type f $fver -c \"rebase from $Branch $Label\" -merge -gmerge";
		print "$merge_cmd\n";
		#print `$merge_cmd`;
	}
}

if (@zeros) {
	printf STDERR "#Zero files: %d\n", scalar @zeros ;
	printf "\n#Zero files: %d\n", scalar @zeros ;

	for my $zf (@zeros) {
		print "# " . $zf . "\n";
		#print "cleartool lshistory -bra $MyBranch -l $zf | grep \"checkout version\" -A1 -B1\n";
	}
}
