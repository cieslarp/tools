#!/usr/local/bin/perl


while (my $line = <>) {
	if ($line =~ /:\d+:/) {
		my @s = split(/\s+/,$line);
		my $str = "[";
		for my $i (3 .. scalar @s) {
			my @chars = split(//,$s[$i]);
			$str .= sprintf "%s%s%s%s",chr(printable(hex($chars[0].$chars[1]))), chr(printable(hex($chars[2].$chars[3]))) ,chr(printable(hex($chars[4].$chars[5]))), chr(printable(hex($chars[6].$chars[7])));
		}	
		print "$s[0] $s[1] $s[2] $str]\n";
	} else {
		print $line;
	}
}

sub printable() {
   my $char = shift;
   if (($char > 31) && ($char < 0xff)) {
      return $char;
   }
   return "";
}
