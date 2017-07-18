#!/usr/local/bin/perl
die <<EOF
$0 - expresion evaluator\n
    right       **
    right       ! ~ \ and unary + and -
    left        * / % x
    left        + - .
    left        << >>
    nonassoc    < > <= >= lt gt le ge
    nonassoc    == != <=> eq ne cmp
    left        &
    left        | ^
    left        &&
    left        ||
    nonassoc    ..  ...
    right       ?:
    right       = += -= *= etc.
    right       not
    left        and
    left        or xor
EOF
if $ARGV[0] =~ /\?/;

$low = 0; $high = 0;
$var="a";
$ch = 'A';
if (scalar @ARGV) {
   while (my $eq = shift(@ARGV)) {
	   if ($eq =~ /^--/) {
		   $i64bit = 1 if ($eq =~ /64/);
	   } else {
		   calc($eq);
	   }
   }
} else {
   while ($eq = <STDIN>) {
      calc($eq,1);
      exit if length($eq) < 2;
   }
}

sub calc() {
  my $ii =  shift;
  my $interactive = shift;
  #print "ii=($ii)\n";
  if ($ii =~ /^.=/) {
     ($var,$low,$high) = split(/=|\.\./,$ii);
     print "var=$var low=$low high=$high\n";
  } elsif (length($ii) > 0){
		   #$ii =~ s/[^\$]*([a-z])/\$\1/g unless $ii =~ /\$[a-z]/;
     if ($ii =~ /=/) {
        do_equation($ii);
     } else {
        for ($$var=$low; $$var < ($high+1); $$var++) {
		   $ii =~ s/(\D+){0}0x/$1hh/g;
		   $ii =~ s/x/*/g unless ($var eq 'x');
		   $ii =~ s/hh/0x/g;
           my $ev = eval($ii);
		   my $iev = $ev;
		   $iev &= 0xffffffff unless $i64bit;
           #printf "\$E[%d]",($#E+1);
           print "$ch:" if $interactive;
           printf "%3d:",$$var if $high;
           printf "%12u (0x%08x)",$iev,$iev;
           printf " %19.5f",$ev;
           @chars = split(//,sprintf("%08x",$ev));
           printf " [%s][%s][%s][%s]\n",chr(printable(hex($chars[0].$chars[1]))), chr(printable(hex($chars[2].$chars[3]))) ,chr(printable(hex($chars[4].$chars[5]))), chr(printable(hex($chars[6].$chars[7])));
           $$ch = $ev;
           $ch++;
           push(@E,$ev);
        }
     }
     $low = 0; $high = 0;
  }
}

sub do_equation {
   my $ii = shift;
   ($ii,$right) = split(/=/,$ii);
   $high = 1000000 if $high == 0;
   $gran = $high;
   $diff = 1;

   while (($diff > (10**(-13)))) {
      $lt=$gt=0;
      $gran = $gran/2;
      #print "g:$gran low=$low high=$high diff=$diff\n";
      for ($$var=$low; $$var < ($high+$gran); $$var+=$gran) {
         $ev = eval($ii);
         $lt = $$var if $ev < $right;
         $gt = $$var if $ev > $right;
         if ($lt && $gt) {
            #print $gran.":".$lt." - ".$gt."\n";
            $diff = $gt - $lt;
            goto _done_with_this_gran;
         }
      }
_done_with_this_gran:
      $low=$lt; $high=$gt;
   }
   print $lt." <-> ".$gt." diff=$diff\n";
}

sub printable() {
   my $char = shift;
   if (($char > 31) && ($char < 0xff)) {
      return $char;
   }
   return "";
}
