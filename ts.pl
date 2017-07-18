#!/usr/local/bin/perl5 -w

$str="20061004:125937.119822 pemr 025 000: file:pem.c;pem_cei";
use HTTP::Date;

($stime, $us, $msg) = $str =~ /(\d{8}:\d{6})\.(\d+) (.*$)/;
print "[$stime]\n";
$time = str2time($stime,"+0000");
print "time=$time\n";
$ntime = $time + 31000;

#convert back to ASCII time with offset but no ms?
print time2str($time) . "\n";
print time2str($ntime) . "\n";

#or POSIX and add us and msg to the end
use POSIX("strftime");
print strftime "%d/%b/%Y %H:%M:%S.$us $msg\n", gmtime($time);
print strftime "%d/%b/%Y %H:%M:%S.$us $msg\n", gmtime($ntime);
exit;














# ts - time stamp
# Perl script which uses the ../config/evt.conf file to calculate
# the time offset for the data collection engineering logs and
# then adds the offset to each entry in the log and prints it to the screen
#
# Author: Joe Eafanti
# Date: 10/26/06


@ARGV < 1 && die "USAGE: $0 log_file\n";

$log_file = $ARGV[0];

# note: since I use month num as index, zero is not value
@mdays = (99,31,28,31,30,31,30,31,31,30,31,30,31);

# check if log file exists
#if (!(-e $log_file.gz)) {
   # log file doesn't exist
#   die "can't open log file $log_file.gz";
#}

# check if file already uncompressed 
if (!(-e $log_file)) {
   # file doesn't exist so unzip the log
   system("gunzip $log_file.gz");
}

# get time offset from evt.conf file
$offset_file = "../config/evt.conf";
&get_time_offset($offset_file);

# 2006/09/19 13:28:16   414     Backup CTP failure 
# 20061004:125937.119822 pemr 025 000: file:pem.c;pem_cei

open (INFILE,"<$log_file") || die "can't open file $log_file";

# read each line out of the log file
while ($line = <INFILE>) {

   ($date,$time,$millisec) = $line =~ m#(\w+):(\w+)\.(\w+) #;
   ($hour,$minute,$second) = $time =~ m#(\w{2})(\w{2})(\w{2})#;
   ($year,$month,$day) = $date =~ m#(\w{4})(\w{2})(\w{2})#;

   &add_time();

   $line =~ s/.{23}//;
   # print "$year/$month/$day $actual_hour:$actual_minute:$actual_second.$millisec $line";
   printf("%02d/%02d/%02d %02d:%02d:%02d.$millisec $line",$year,$month,$day,
           $actual_hour,$actual_minute,$actual_second);

}

# open evt.conf, read, and calculate time offset
sub get_time_offset
{
   my ($file) = @_;

   # check if file already exists
   if (!(-e $file)) {
      # file doesn't exist
      system("gunzip $file.gz");
   }

   open (INFILE,"<$file") || die "can't open file $file";

   # get the first line of the file
   $line = <INFILE>;
   # get the second line - offset in seconds
   $line = <INFILE>;
   chop($line);  # remove newline (end of line)

   $offset_minutes = int ($line / 60);
   $offset_hours = int ($offset_minutes / 60);
   $offset_seconds = int ((($line/60) - $offset_minutes) * 60);
   $offset_minutes = int ($offset_minutes - ($offset_hours * 60));

   print "seconds offset [$line] Time Offset: [$offset_hours:$offset_minutes:$offset_seconds]\n";

   close(INFILE);
}

# sets actual_hour, actual_minute, actual_second, month, day, year
sub add_time()
{
   # calculate actual time (i.e. add offset)

   if (($second + $offset_seconds) > 59)
   {
      $offset_minutes++;
   }
   $actual_second = ($second + $offset_seconds) % 60;

   if (($minute + $offset_minutes) > 59)
   {
      $offset_hours++;
   }
   $actual_minute = ($minute + $offset_minutes) % 60;

   if (($hour + $offset_hours) > 23)
   {
      $day++;
   }
   $actual_hour = ($hour + $offset_hours) % 24;

   if (&IsLeapYear($year) && ($month == 2))
   {
      if ($day > 29)
      {
         $month++;
         $day = 1;
      }
   }
   else
   {
      if ($day > $mdays[$month])
      {
         $month++;
         $day = 1;
      }
   }

   if ($month > 12)
   {
      $year++;
      $month = 1;
   }
}

sub IsLeapYear
{
   my $year = shift;
   return 0 if $year % 4;
   return 1 if $year % 100;
   return 0 if $year % 400;
   return 1;
}

