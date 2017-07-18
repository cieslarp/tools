#!/usr/local/bin/perl

$routef = shift || "/vobs/projects/springboard/fabos/src/sys/dev/asic/condor2/c2_route.c";
$tracef = shift || "/vobs/projects/springboard/fabos/src/sys/include/trace/trace_c2_events.h";

print "RF=($routef) TF=($tracef)\n";
open(RF, $routef) || die "Could not open $routef\n";
open(TF, $tracef) || die "Could not open $tracef\n";
open(NTF, ">new_trace.h") || die;
open(OTF, ">old_trace.h") || die;

$traceid = 0;
while (my $line = <RF>) {
	chomp($line);
	1 while ($line =~ s/^\s+//g);
	if ($line =~ /rte_trace\((\d+)/) {
		$traceid = $1;
		$entry = "";
	} 
	if ($traceid != 0) {
		$entry .= $line;
		if ($line =~ /\)/ && $line =~ /;/) {
			#print "==$entry==\n";
			$entry =~ s/\"\"//g;
			my ($e) = $entry =~ /\((.*)\)/;
			my ($tn,$sev,$str) = split(/\s*,\s*/, $e, 3);
			($sev) = $sev =~ /ASIC_([A-Z]+)_LEVEL/;
			my ($hdr, $str,$rest) = split(/\"/,$str);
			#print "tn($tn) sev($sev) str($str)\n";
			$sev .= "S" if $sev eq "WARN";
			$str .= "\\n" unless $str =~ /\\n$/;
			$tracestr = sprintf("TRACE_EVENT_ID(C2_ASIC_RTE_$sev$tn, (ASIC_RTE << 11) + $tn,X(\"$str\"))\n");
			if (!defined($Trace{$traceid})) {
				#print "$e\n";
				$Trace{$traceid} = $tracestr;
			}
			$traceid = 0;
		}
	}
}
for my $traceid (sort {$a <=> $b} keys %Trace) {
	print NTF $Trace{$traceid};
}


$traceid = 0;
while (my $line = <TF>) {
	chomp($line);
	1 while ($line =~ s/^\s+//g);
	if ($line =~ /TRACE_EVENT_ID.*ASIC_RTE_([A-Z]+)(\d+),/) {
		$sev = $1;
		$traceid = $2;
		if ($line !~ /$traceid,/) {
			print "Mismatched traceid: $traceid line($line)\n";
		}
		$entry = "";
	}
	if ($traceid != 0) {
		$entry .= $line;
		if ($line =~ /\)\)/) {
			#print "==$entry==\n";
			$entry =~ s/\"\"//g;
			print OTF "$entry\n";
			if (defined($Trace{$traceid})) {
				#print "rte_trace[$Trace{$traceid}]\n";
				#print "Trace    [$entry]\n";
			} else {
				#print "Entry not used: [$entry]\n";
			}
			$traceid = 0;
		}
	}
}
