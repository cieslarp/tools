$sep = ' ';
$DispCount = 30;
foreach $arg (@ARGV) {
   if ($arg =~ /^-/) {
      $sep = "\\s+" if $arg =~ /-w/;
      $sep = "notgoingtohappen"  if $arg =~ /-l/;
      $DispCount = substr($arg,2) if $arg =~ /-c/;
   } else {
      push(@files,glob($arg));
   }
}
print "[".$sep."]\n";
foreach $file (@files) {
   if (open(WCFILE,"xml $file |")) {
      $long = 0;
      $chars=0;
      $lines=0;
      %c = {};

      while ($line = <WCFILE>) {
         chomp($line);
         $linelen = length($line);
         $long = $linelen if $linelen > $long;
         $line =~ s/\<.*\>//g;
         1 while $line =~ s/,|\'|\"|\-|\!|\?|\.|\&//g;
         $chars += $linelen;
         foreach $ch (split(/$sep/,$line)) {
            $ch = lc($ch);
            if ($ch =~ /[a-z]|\'/) {
                $c{$ch}++;
                $words++;
            }
         }
         $lines++;
      }
      printf "%-30s chars=%10u lines=%10u average=%4u long=%4u words=%4u uniq=%u\n",
              $file,$chars,$lines,($chars/($lines+1)),$long,$words,scalar keys %c;
      my @vs = ();
      while (($k,$v) = each(%c)) {
         push(@vs,"$v�$k");
      }
      my $count = 0;
      my $disptot = 0;
      foreach $l (reverse sort(lsort @vs)) {
         my @s = split(/�/,$l);
         printf "%10u %s\n",@s;
         $disptot += $s[0];
         last if $count++ > $DispCount;
      }
      printf "%u/%u (%f)\n",$disptot,$words,($disptot/$words)*100;
   }
}



###############################################################
sub lsort {
   ($a1) = split(/ /,$a);
   ($b1) = split(/ /,$b);
   return ($a1) <=> ($b1);
}

