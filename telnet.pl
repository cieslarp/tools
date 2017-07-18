#!/usr/local/bin/perl
use POSIX qw(strftime);
my $host = shift;
my $port = shift;

my $now_string = strftime "%d%b%Y_%H%M%S", localtime;
my $log_file = $ENV{HOME} . "/logs/" . $now_string. "_" . $host;
if ($port) {
	$log_file .= "_" . $port;
}
$log_file .= ".log";

print STDERR "Log(" . $log_file . ")\n";

system("/usr/kerberos/bin/telnet $host $port @ARGV | tee -a $log_file");
system("gzip $log_file");
