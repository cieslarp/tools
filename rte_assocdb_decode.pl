#!/usr/local/bin/perl

# from /vobs/projects/springboard/fabos/src/sys/include/fabos/if.h
#define IF_PROPERTY_RTE_HNDL 1 /* RTE's private handle */
#define IF_PROPERTY_EGID     2 /* egress ID, set by RPM, used by Condor ASIC */
#define IF_PROPERTY_BW       3 /* bandwidth, 1 = 1Gb/sec */
#define IF_PROPERTY_AREA     4 /* area number, for user ports only */
#define IF_PROPERTY_USR_PORT 5 /* user port index, if applicable */
#define IF_PROPERTY_SWEL     6 /* pointer to switch element/miniswitch parent */
#define IF_PROPERTY_LOG_PORT 7 /* index relative to miniswitch parent */
#define IF_PROPERTY_PEER_IF  8 /* peer interface, for internal ports only */

#/* Interface various attribute bitmap, for now only 'active' is defined */
#define IF_PROPERTY_STATE               10
#define IF_STATE_ACTIVE 0x00000001

#define IF_PROPERTY_EMBEDDED     11 /* true for embedded if, one per minisw */
#/* handle of master port, applies to internal and external ports */
#define IF_PROPERTY_MASTER_HNDL  12

#define IF_PROPERTY_INST_SWITCH  13 /* I/F Instance within a switch */
#define IF_PROPERTY_INGRESS_ID   14 /* The ingress ID of the interface */
#define IF_PROPERTY_UPLINK_VC    15 /* The uplink VC of the interface */
#define IF_PROPERTY_DOWNLINK_VC  16 /* The downlink VC of the interface */
#define IF_PROPERTY_QUE_MODE     17 /* The Q selection of the interface */
#define IF_PROPERTY_ASSOCIATE    18 /* associate handle of the interface */

#define IF_PROPERTY_TXVCMODE     19 /* Tx VC mode of the interface */
#define IF_PROPERTY_RXVCMODE     20 /* Rx VC mode of the interface */
#define IF_PROPERTY_SHARED   21 /* true for shared if (shared area destination) */
#define IF_PROPERTY_DRS      22 /* DRS of the interface */
#define IF_PROPERTY_PRIMARY  23 /* primary ifid associated with primary shared ifid */
#define IF_PROPERTY_SECONDARY    24 /* secondary ifid associated with secondary shared ifid */
#define IF_PROPERTY_SW_INST  25 /* Switch instance associated with the interface */
#define IF_PROPERTY_MULTICAST    26 /* true for multicast if, one per minisw */
#define IF_PROPERTY_PORT_INDEX   27
#define IF_PROPERTY_EMB_FWD      28 /* Embedded IF, but needs forward to down link in the core */
#define IF_PROPERTY_MULTI_IFID   29
#define IF_PROPERTY_FCOE_PEER    30 /* Peer is an FCoE port (Eg. C2->Zeus) */

#Example
#Interface: 0x43120004:Type L:Rcnt 6:nchild 1:nparent 4:Hndls phy(0x43120004), lgcl(0xa041a000)
#PROPERTIES:0x0 0x9bbac800 0xffffffff 0x3e80 0xffffffff 0xffffffff 0x43110000 0x24 0x43520814 0x0 0x1 0x0 0x43128004 0x0 0xffffffff 0xffffffff 0xffffffff 0x0 0xa041a000 0x0 0x0 0x0 0xffffffff 0x0 0x0 0xffffffff 0x0 0xffffffff 0x0 0
#Children:0x43120004
#Parents:0x9bab99e0 0x9bb9e2c0 0x9bb37540 0x9bbabbe0

%If_prop =(
	"RTE_HNDL" => 1,
	"EGID"     => 2,
	"BW"       => 3,
	"AREA"     => 4,
	"USR_PORT" => 5,
	"SWEL"     => 6,
	"LOG_PORT" => 7,
	"PEER_IF"  => 8,
	"STATE"    => 10,
	"EMBEDDED"     => 11,
	"MASTER_HNDL"  => 12,
	"INST_SWITCH"  => 13,
	"INGRESS_ID"   => 14,
	"UPLINK_VC"    => 15,
	"DOWNLINK_VC"  => 16,
	"QUE_MODE"     => 17,
	"ASSOCIATE"    => 18,
	"TXVCMODE"     => 19,
	"RXVCMODE"     => 20,
	"SHARED"   => 21,
	"DRS"      => 22,
	"PRIMARY"  => 23,
	"SECONDARY"    => 24,
	"SW_INST"  => 25,
	"MULTICAST"    => 26,
	"PORT_INDEX"   => 27,
	"EMB_FWD"      => 28,
	"MULTI_IFID"   => 29,
	"FCOE_PEER"    => 30,
);

@if_props = (
	"PROP_0",
	"RTE_HNDL", #1,
	"EGID",    #2,
	"BW", # 3,
	"AREA", # 4,
	"USR_PORT", # 5,
	"SWEL", # 6,
	"LOG_PORT", # 7,
	"PEER_IF", # 8,
	"PROP_9",
	"STATE", # 10,
	"EMBEDDED", # 11,
	"MASTER_HNDL", # 12,
	"INST_SWITCH", # 13,
	"INGRESS_ID", # 14,
	"UPLINK_VC", # 15,
	"DOWNLINK_VC", # 16,
	"QUE_MODE", # 17,
	"ASSOCIATE", # 18,
	"TXVCMODE", # 19,
	"RXVCMODE", # 20,
	"SHARED", # 21,
	"DRS", # 22,
	"PRIMARY", # 23,
	"SECONDARY", # 24,
	"SW_INST", # 25,
	"MULTICAST", # 26,
	"PORT_INDEX", # 27,
	"EMB_FWD", # 28,
	"MULTI_IFID", # 29,
	"FCOE_PEER", # 30,
);

my $Ifid = 0;
my $file = shift;
if (-e $file) {
	open(IF_TREE, "$file") || die "Could not open $file\n";
} elsif ($file =~ /\d+\.\d+\.\d+\.\d+/) {
	print "ssh to $file\n";
	open(IF_TREE, 'switchssh 10.38.17.102 "cat /proc/fabos/idmgr/if_tree" |') || die "Could not ssh to $file\n";
} else {
	die "$0 <file | ipaddress>";
}

while (my $line = <IF_TREE>) {
	my @s = split(/[:|\s]+/,$line);
	print "S0[" . $s[0] . "]: (" . join(',',@s) . ")\n" if $Debug;
	if ($s[0] =~ /Interface/) {
		$Ifid = hex($s[1]);
		$Lgcl = $s[12];
		print "set ifid[" . $s[1] . "]\n" if $Debug;
		$morechild = 0;
	}
	elsif ($s[0] =~ /PROPERTIES/) {
		my ($pt,@p) = @s;
		printf "ifid=%x %s u:%3d i:%d e:%d\n", $Ifid, $Lgcl, hex($p[$If_prop{"USR_PORT"}]), hex($p[$If_prop{"INST_SWITCH"}]), hex($p[$If_prop{"EGID"}]);
		foreach my $ii (0..scalar(@s)) {
			printf("%08x: %11s[%2d]: %d(%x)\n", $Ifid, $if_props[$ii], $ii, hex($p[$ii]), hex($p[$ii]));
		}
	} elsif ($s[0] =~ /Children|Parents/) {
		printf("%08x: $line", $Ifid);
		$morechild = $s[0] =~ /Children/;
	} elsif ($morechild && $s[0] =~ /0x/)  {
		printf("%08x: Children:$line", $Ifid);
	}
}
close(IF_TREE);

sub if_prop_str() {
	my $prop_num = shift;

	for my $i (keys(%if_prop)) {
		return $if_prop{$i} if $if_prop{$i} = $i;
	}
	return "?";
}

