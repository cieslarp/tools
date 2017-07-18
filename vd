#!/usr/local/bin/perl
use File::Basename;
use Cwd;

$Verbose = 0;
$Created_f = 0;
$Opt = "";
$quiet = "";
$PrintOnly = 0;

foreach $arg (@ARGV)
{
   $cr=0;
   print "(".$arg.")\n" if $Verbose;
   if ($arg =~ /^-/) {
      $Difftype = substr($arg,2) if lc($arg) =~ /-d/;
      $cr = substr($arg,2)       if lc($arg) =~ /-r/;
      $cr = "get_last_rev"       if lc($arg) =~ /-r-/;
      $cr = "get_file_rev"       if lc($arg) =~ /-r$/;
      $cr = "get_latest"         if lc($arg) =~ /-l/;
	  $cr = "get_base"           if lc($arg) =~ /-rz/;
      push(@currel,$cr) if $cr;
      $Opt      = substr($arg,1) if lc($arg) =~ /--/;
	  $PrintOnly++               if lc($arg) =~ /-p/;
      $quiet    = "-q "          if lc($arg) =~ /-q/;
      $Verbose++                 if lc($arg) =~ /-v$/;
   }
   else { push(@files,$arg); }
}

unless ($Difftype) {
	$Difftype = "vimdiff -R" if $0 =~ /vd/;
	$Difftype = "diff"       if $0 =~ /td/;
}
$file1 = shift(@files);
$file2 = shift(@files);
$file3 = shift(@files);
if (!$file2 && $file1 =~ /@@/) {
	($file1,@rels) = split(/@@/, $file1);
	my $prevrel = $rels[0];
	$prevrel =~ s/([0-9]+)$/$1-1/eg;

   	unshift(@rels, $prevrel);
} else {
	if (!$file2 && $#currel<0) { push(@currel,"get_latest"); };
	($file1) = `ls -la $file1` =~ /^l.* -> (.*)$/ if -l $file1;
	($file1) = `ls -la $file1` =~ /^l.* -> (.*)$/ if -l $file1;
	$f1rev = get_file_rev($file1);
	$f1bev = $f1rev;
	$f1bev =~ s/\/([0-9]+)$//;
	$f1num = $1;
}

foreach $cr (@currel) {
   print "cr=$cr\n" if $Verbose;

   if ($cr eq "get_file_rev") {
      unshift(@rels, $f1rev);
   } elsif ($cr eq "get_last_rev") {
      unshift(@rels, $f1bev."/".(($f1num) ? ($f1num-1) : 0));
   } elsif ($cr eq "get_latest") {
      unshift(@rels, $f1bev."/LATEST");
   } elsif ($cr eq "get_base") {
      unshift(@rels, $f1bev."/0");
   } else {
      unshift(@rels, $f1bev."/".$cr);
      print "Adding rel: $cr\n" if $Verbose;
   }
}

$file2 = $file1 . "@@" . $rels[0] if ($rels[0]);
$file1 = $file1 . "@@" . $rels[1] if ($rels[1]);

if ($Verbose) {
    print "f1rev=($f1rev)\n";
    print "f1bev=($f1bev)\n";
    print "f1num=($f1num)\n";
    print "f1=($file1)\n";
    print "f2=($file2)\n";
    print "r0=($rels[0])\n";
    print "r1=($rels[1])\n";
}

$file2 = $file2 . "/" . $file1 if (-d $file2);

die "File not found: $file1\n" unless $file1;
die "No second file\n" unless $file2;

if (!(-e $file2) && (-d "/view/$file2")) {
	my $base = ($file1 =~ /^\//) ? dirname($file1) : &Cwd::cwd();
	print "File2 from view: $file2 base:$base basename:" . basename($file1) . "\n";
	$file2 = "/view/$file2" . $base . "/" . basename($file1);
}

die "Second File not found: $file2\n" unless -e $file2;

if (-d $file1) {
	$Difftype = "cleartool diff";
}

$dline = $Difftype." $Opt $file1 "." $file2";
$dline .= " $file3" if ($file3 ne "") && (-e $file3);

print $dline."\n" unless $quiet;
system($dline) unless $PrintOnly;

exit;







########################
sub get_file_rev() {
   my $file = shift;
   my $out = `/opt/rational/clearcase/bin/cleartool ls $file`;
   $out =~ /.*@@(.*)Rule:/;
   my @s = split(/\s+/,$1);
   if ($s[0] =~ /CHECKEDOUT/ && $s[1] eq "from") {
       $s[2] =~ s/\s+//g;
       return $s[2];
   } else {
       $s[0] =~ s/\s+//g;
       return $s[0];
   }
}
