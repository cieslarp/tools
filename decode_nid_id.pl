#!/usr/local/bin/perl

#Node: 0x84ff032f :Type L:Rcnt 1:nchild 0:nparent 0:Hndls phy(0x0), lgcl(0x84ff032f)
#PROPERTIES:0x32f 0x4 0xc9 0x1 0xff 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0

#    nd->id_properties[ID_PROPERTY_PRIV_HNDL] = inst;
#    nd->id_properties[1] = sub_type;
#    nd->id_properties[2] = node_index;
#    nd->id_properties[3] = type;
#    nd->id_properties[4] = rgid;

while (my $line = <>) {
	if ($line =~ /^PROPERTIES:/) {
		my @s = split(/:/,$line);
		my @p = split(/\s+/,$s[1]);
		my @n = split(/\s*:\s*/,$prev);
		printf "addr=%s inst=%08x sub_type=%d node_index=%4d type=%d rgid=%d\n", $n[1], hex($p[0]), hex($p[1]), hex($p[2]), hex($p[3]), hex($p[4]);
		if ($nc[hex($p[4])][hex($p[2])]) {
			printf "Duplicate with addr=%s!!!\n", $nc[hex($p[4])][hex($p[2])];
		}
		$nc[hex($p[4])][hex($p[2])] = $n[1];

		
	}
	$prev = $line;
}



