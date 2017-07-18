$filename = shift || die "$0 <file to lstat>\n";    
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
           $atime,$mtime,$ctime,$blksize,$blocks)
                      = lstat($filename);

printf ("dev=%u ino=%u mode=%s nlink=%u uid=%u gid=%u rdev=%u size=%u atime=%u mtime=%u ctime=%u blksize=%u blocks=%u\n", 
    $dev,$ino,mode_to_string($mode),$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks);

sub mode_to_string() {
   my $octmode = shift;
   my $orig = $octmode;
   my @mbits = ();
   for (1..3) {
      push(@mbits, ($octmode & 01) ? 'x' : '-');
      push(@mbits, ($octmode & 02) ? 'w' : '-');
      push(@mbits, ($octmode & 04) ? 'r' : '-');
      $octmode >>= 3;
   }
   if    ($octmode & 040 ) { push(@mbits,'d'); }
   elsif ($orig & 0x2000) { push(@mbits,'l'); }
   elsif ($octmode & 0100) { push(@mbits,'-'); }
   else  { push(@mbits,sprintf("%x",$orig)); }
   return join('',reverse(@mbits));
}

