#!/usr/local/bin/perl

while (my $line = <>) {
	if ($line =~ /Bucket (\d+):\s+Entry/) {
		$bucket = $1
	}
	if ($line =~ /Bucket (\d+):\s+Flow index/) {
		$bucket = $1;
		$ni = 0;
	}
	if ($line =~ /Entry (0x\w+) .num_items:(\d+)/) {
		$entry = $1;
		$ni = $2;
	}
	if ($line =~ /Entry(\d+):/) {
		$entry = $1;
		$ni++;
	}
	if ($line =~ /(SID[\s|:]0x.*VFID.*)/) {
		$key = $1;
		$Bucket{$bucket} .= (join(',',$entry, $ni, $key)) . ",";
		$Bc{$bucket}++;
		$TotalPairs++;
	}
	$filtercheck++ if ($line =~ /filterportshow/);
	last if $filtercheck > 1;
}
my @sorted_bucket_keys = sort {$Bc{$b} <=> $Bc{$a}} keys (%Bc);

foreach my $k (@sorted_bucket_keys) {
	$Count_per_Bucket{$Bc{$k}}++;
	$TotalBuckets++;
}

foreach my $k (sort {$b <=> $a} keys (%Count_per_Bucket)) {
	printf "%d = %d\n", $k, $Count_per_Bucket{$k};
}
printf "Total Buckets=%d Total Pairs=%d\n", $TotalBuckets, $TotalPairs;

foreach my $k (@sorted_bucket_keys) {
	print "[" . $Bc{$k} . "]," . $k . "," . $Bucket{$k} . "\n";
}
