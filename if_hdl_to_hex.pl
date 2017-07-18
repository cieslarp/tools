#!/usr/local/bin/perl

#RTE_TE_TI_CSTRNTS_SET       20:43:43.478279 TI cstrnts set: if_hdl 1125253136, cdata 0x0, ti_group_num 1, failover 0, edge_cstrnt 0

while (my $line = <>) {
	if ($line =~ /if_hdl (\d+),/) {
		my $hif = sprintf("%08x", $1);
		$line =~ s/if_hdl (\d+),/if_hdl 0x$hif,/;
	}

	print $line;
}

