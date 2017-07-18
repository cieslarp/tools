#!/usr/local/bin/perl

exec("perl /vobs/projects/springboard/fabos/src/sys/route/new/simulator/run_sim_preprocess.pl @ARGV") if -e "/vobs/projects/springboard/fabos/src/sys/route/new/simulator/run_sim_preprocess.pl";
print "use /vobs/projects/springboard/fabos/src/sys/route/new/simulator/run_sim_preprocess.pl\n";
