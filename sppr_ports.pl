$reg = hex(shift);
$reg = ($reg & 0xFFFFF) | 0xC000000;

for my $spp (0..1) {
    for my $port (0..15) {
        printf "sppr 0%x 1 $spp\n", ($reg | ($port<<20)) ;
    }
}

