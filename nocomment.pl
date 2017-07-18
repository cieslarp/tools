#!/usr/bin/perl

$file = shift;
if (open(CFILE,$file)) {
   # Read the entire file as one string
   read(CFILE,$program,2000000000);

   # Remove /*  */ comments
   $program =~ s/\/\*.*?\*\///gsxm;

   # Remove #if 0 comments
   $program =~ s/\#if\s+0.*?\#endif//gsxm;
}

foreach $line (split(/\n/,$program)) {
   #Remove // comments
   $line =~ s/\/\/.*//; 
   print $line."\n" if $line;
}

