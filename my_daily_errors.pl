#!/usr/local/bin/perl -w
# Author: Terry V. Bush (The Veritable Bugeater)


# Declare and initialize all vars.
$error_num = 0;
$error_target = "";
$error_chunks = 0;
$error_txt = "";
$error_tot = 0;

$cur_target = "";
$cur_dir = "";
$cur_chunk = "";
$last_pushed_dir = "";
@dir_stack = ();

use POSIX qw(strftime);
$now_string = strftime "%d%b%Y_%H%M%S", localtime;

$make_log  = "/vobs/sanera/mkweekly_" . $now_string . ".log";
$error_log = "/vobs/sanera/mkweekly_" . $now_string . ".err";
open (MKLOG,  ">$make_log")  or die "$! : $make_log\n";
open (ERRLOG, ">$error_log") or die "$! : $error_log\n";


sub print_errors()
{
    if ($error_num != 0) {
	# Print the current chunk with the error.
	$error_chunks++; # Track the number of errors.
	print "Error while Making $cur_target in $cur_dir\n";
	print "  trying to make $error_target\n";
	print "  in directory $last_pushed_dir\n";
	print "$error_txt\n";
	$error_txt = "";
	print ERRLOG "\043\043=-=-= Error while Making $cur_target ($error_target) in $cur_dir ($last_pushed_dir) =-=-=\043\043\n";
	print ERRLOG "$cur_chunk\n\n";
    }
}


while (<>) {
    print MKLOG;

    # This line keeps track of what dir and target we are building.
    if ((eof) || (/^Making ([^ \t]+) in (.*)/)) {
	&print_errors();
	if (! eof) {
	    # Collect pertinent info.
	    $cur_target = $1;
	    $cur_dir = $2;
	    $cur_chunk = $_; # Reset $cur_chunk since we've started a new chunk.
	    $error_num = 0; # Reset $error_num too.
	}
	next;
    }

    # This line keeps track of what directory make thinks we are entering.
    if (/^make(\[[0-9+]\])*: Entering directory \140(.*)\047/) {
	push (@dir_stack, $2);
	&print_errors();
	$last_pushed_dir = $2;
	$cur_chunk = $_; # Reset $cur_chunk since we've started a new chunk.
	$error_num = 0; # Reset $error_num too.
	next;
    }

    # This line keeps track of what directory make thinks we are leaving.
    if (/^make(\[[0-9+]\])*: Leaving directory \140(.*)\047/) {
	local($popped_dir) = '';
	$popped_dir = pop (@dir_stack) if (@dir_stack);
	$cur_chunk .= $_;
	if ($popped_dir ne $2) {
	    print "Popped dir '$popped_dir' and Leaving dir '$2' don't match.\n";
	}
	next;
    }

    # This line finds the errors.
    if (/^make(\[[0-9+]\])*:[\s*]*\[(.*)\]\s*Error\s*([0-9]+)\s*(\(ignored\))*/) {
	$error_target = $2;
	$error_num = $3;
	$cur_chunk .= $_;
	$error_txt .= $_;
	$error_tot++;
	next;
    }

    # This line finds the errors like: "make: *** No rule to make target `no-such-target'.  Stop."
    if (/^make(\[[0-9+]\])*:[\s*]*No rule to make target \140(.*)\047\.\s*Stop\./) {
	$error_target = $2;
	$error_num = 1;
	$cur_chunk .= $_;
	$error_txt .= $_;
	$error_tot++;
	next;
    }


    # Tag all the other lines into the $cur_chunk buffer.
    $cur_chunk .= $_;


}

print "\nChunks with Errors: $error_chunks\n";
print "Total Errors: $error_tot\n";

close ERRLOG;
close MKLOG;

exit($error_tot != 0);
