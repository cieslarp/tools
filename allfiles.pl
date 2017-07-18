#!/usr/bin/perl
use Digest::MD5  qw(md5_hex);
$|=1;
$debug = 0;
chomp($view = `/usr/atria/bin/cleartool pwv -s`);
$SaveDir = (-d $ENV{ALLFILES_DIR}) ? $ENV{ALLFILES_DIR} : "/tmp";
$SaveName= $SaveDir . "/" . $view;
$All = 0;
$Java = 0;
foreach $arg (@ARGV) {
    if ($arg =~ /^-/) {
        $debug = substr($arg,2) if $arg =~ /-d/;
        if ($arg =~ /-a/) { push(@ext,"*") ; $All=1; }
        if ($arg =~ /-e/) { push(@ext,substr($arg,2)) ; }
		$Java ^= 1 if $arg =~ /-j/i;
    }
    else {
        push(@dirs,$arg);
    }
}

push(@dirs,( # avoid lost+found
		    "/vobs/projects/springboard/fabos/src",
		    "/vobs/projects/springboard/fabos/bccb",
			"/vobs/projects/springboard/fabos/bfos",
			"/vobs/projects/springboard/fabos/bin",
			"/vobs/projects/springboard/fabos/dfos",
			"/vobs/projects/springboard/fabos/dmm",
			"/vobs/projects/springboard/fabos/doc",
			"/vobs/projects/springboard/fabos/sas",
			"/vobs/projects/springboard/fabos/share",
            "/vobs/projects/fcr",
			"/vobs/projects/springboard/common_src",
			"/vobs/projects/springboard/dist",
			"/vobs/projects/springboard/make",
			"/vobs/projects/springboard/tps/ZebOS",
		   )) unless scalar @dirs;

if (scalar @dirs == 0) {
	foreach my $d (glob("/vobs/projects/springboard/fabos/*")) {
		next unless -d $d;
		push (@dirs, $d) unless $d =~ /lost.found\|^cfos$/g;
	}
	push(@dirs, (
            "/vobs/projects/fcr",
			"/vobs/projects/springboard/common_src",
			#"/vobs/projects/springboard/dist",
			"/vobs/projects/springboard/make",
			));
}

@ext = ("*.c","*.cpp","*.h","*.pl", "*.pm", "*.py", "*.mk", "*.make", "*.yang", "*.cli", "Make*", "*.exp", "*.sh", "*.xml", "*.msg", "*.1m", "*.in", "*.conf", "*.awk", "*.sh", "install", "fabos", "cov_gk_info") unless scalar @ext;
if ($Java) {
	push(@dirs, "/vobs/multisite/webtools/fabos/java");
	push(@ext,"*.java");
}
my @n = ();
foreach my $e (@ext) {
    push(@n, "-name '$e'");
}
my $names = "\\\( " . join(" -or ",@n) . " \\\)";
print $names . "\n" if $debug > 1;
%Tokens = %FID4TID = ();
@Files = ();
$TokenID = $FileID = 0;
foreach my $dir (@dirs) {
    print "scanning files in: $dir\n" if $debug;
	unless (-d $dir) {
		print "Could not find $dir\n";
		next;
	}
    $dir = $dir . "/" unless $dir =~ /\/$/;

    print "find $dir $names -type f -print \n" if $debug;
    printf "\n%80s %9d:%9d", $f, $FileID, $TokenID if $debug;
    if (open(FILELIST,"find $dir $names -type f -print |")) {
		while (my $f = <FILELIST>) {
		   chomp($f);
		   $f =~ s/\/+/\//g;

		   print chr(8) x 100 if $debug; 
		   printf "%-80s %9d:%9d", substr($f,0,80), $FileID, $TokenID if $debug;
		   
		   #do not process these huge files
		   next if $f =~ /lgen-1.*in$/;
		   next if $f =~ /\/mibgc\/.*\.c$/;
		   printf "!\n" if $f =~ /lost\+found/ && $debug;
		   next if $f =~ /lost\+found/;
		   #next if $f =~ m|^/vobs/projects/springboard/fabos/src/diag|;

		   if ($All) { 
			   my $ft = `file -b $f`; 
			   #print $f . ":" . $ft unless $ft =~ /text/;
			   next unless $ft =~ /text/; 
		   }

		   process_file($f);
		}
	}
    printf "\n Tokens=%d FID4TID=%d Files=%d\n", scalar keys %Tokens, scalar keys %FID4TID, scalar @Files if $debug;
}
save_data();
print "done\n" if $debug;
read_data();






##################################################################################
# save_data()
# Given all Tokens collected from all files scaned, create a mapping of all the
# file ids that contain the tokens, also create a mapping of file id to filename
# Output:
#	*.tokens: a list of all tokens with the associated file id position
#	*.t4f	: lists of file ids that all contain similar tokens
#	*.files	: list of all files with the associated file id
##################################################################################
sub save_data() {
    my @tokens = keys %Tokens;

    print "save $SaveName.tokens\n" if $debug;
    open(TOKENS,">$SaveName.tokens") || die "Error creating $SaveName.tokens: $!\n";
    open(T4F,">$SaveName.t4f") || die;
    my $Pos = 0;

	# From the list of File IDs for each line index, create a csv list of file groupings
	foreach my $fid (keys %FID4TID) {
		my $fid_group_str = $FID4TID{$fid};
		if (!defined $FIDPos{$fid_group_str}) {
			$FIDPos{$fid_group_str} = $Pos;
			$Pos += length($fid_group_str) + 1;
			print "fid_group_str[$fid_group_str] Pos[$Pos]\n" if $debug > 2;
			print T4F $fid_group_str . "\n";
		}
	}

	# For each token, save the position of the list of file ids
    foreach my $tok (@tokens) {
		# For this line, get the list of File IDs
        my $str = $FID4TID{$Tokens{$tok}};
		print "tok[$tok] str[$str] Tokens[$Tokens{$tok}] Pos[$FIDPos{$str}]\n" if $debug > 2;
        print TOKENS $FIDPos{$str} . ":" . $tok . "\n";
		delete $FID4TID{$Tokens{$tok}};
        printf "%9u:%15u:$tok\n", $Tokens{$tok}, $Pos if ($debug && $ldump++ < 20);
        print chr(8) x 21 if $debug;
        printf "%10u/%10u", $ldump, scalar @tokens if $debug;
    }
    printf "\nToken count   : %d\n", scalar @tokens if $debug;
	printf "File Mappings : %d\n" , scalar keys %FIDPos if $debug;
	printf "File count    : %d\n" , scalar @Files if $debug;

    print "save $SaveName.files\n" if $debug;
    open(FILES,">$SaveName.files") || die;
    print FILES join("\n",@Files) . "\n";
    close(FILES);
	$csf = $ENV{CSCOPE_DB};
	$csf =~ s/\.out/.files/g;
	print "cscope file = ($csf)\n" if $debug;

	if (open(CSF, ">$csf")) {
		open(FILES, "$SaveName.files") || die;
		while (my $f = <FILES>) {
			next if $f =~ /route\/legacy/; # Skip Legacy RTE
			next if $f =~ /\/fabos\/cmodel/; # Skip Cmodel directories
			print CSF $f if ($f =~ /\.[c|h](pp)*$/);
		}
		close(CSF);
		close(FILES);
	}
}


##################################################################################
# process_file(filename)
# Read through a given file and seperate out each token.
# Keep track of every token with an id which is incremented for each unique token. 
# Then for each token add this file's unique id to a list of file ids.
##################################################################################
sub process_file() {
   my $f = shift;
   my %file_token_ids = ();
   my $token_count = 0;
   my $file_content = "$f,";

   if (open(CFILE, $f)) {
	   while (my $line = <CFILE>) {
		   foreach my $tok (split(/\W+/, lc($line))) {
			   next unless length($tok);
			   $Tokens{$tok} = $TokenID++ unless defined($Tokens{$tok});
			   $file_token_ids{$Tokens{$tok}} = $tok;
			   $token_count++;
		   }
	   }
	   close(CFILE);
   }

   printf "Large file: $f, $token_count tokens\n" if ($token_count > 200000);

   foreach my $tid (sort keys %file_token_ids) {
	   $FID4TID{$tid} .= "$FileID,";
	   #$file_content .= $file_token_ids{$tid} . "($tid)" . ",";
   }
   #print "pre: file_content[$file_content]\n";
   #$file_content = md5_hex($file_content) . ":" . $file_content;
   #print "file_content[$file_content]\n";
   #exit;

   # Save the unique file id for this file
   # TBD: could this be made unique globally for incremental file additions?
   #my $filename_md5_hash = md5_hex($f);

   #if (defined $Filenamesbymd5{$filename_md5_hash}) {
	   #die "already defined has{$filename_md5_hash} for file $Filenamesbymd5{$filename_md5_hash} same as f[$f]\n";
   #}
   #$Filenamesbymd5{$filename_md5_hash} = $f;
   #printf "file[%60s] : md5[$filename_md5_hash]\n", $Filenamesbymd5{$filename_md5_hash} if $debug;
   $Files[$FileID++] = $f;
}


sub read_data() {
	# 1. Read *.files to @Files and set $FileID
	# 2. Read *.tokens to repopulate %Tokens with $Token{token} = token_id
	# 3. Read *.t4f to get the file ids?
}
