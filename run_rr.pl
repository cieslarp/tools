#!/usr/bin/perl

$build_dir = "/vobs/projects/springboard/build/asic-sim/new";
$tmp_in = "$build_dir/ce2-input";

sub run_sim {
        my ($sim, $seed_start, $seed_end, $events, $platform) = @_;

        print "\nSimulator = $sim\n";
        print "Seeds = [ $seed_start ... $seed_end ]\n";
        print "Events per run = $events\n\n";

        for (my $i = $seed_start; $i <= $seed_end; $i++) {
                system("echo \"13\n$events\n0\" > $tmp_in");
                $tmp_out = "$build_dir/out.runs.$platform.$i";

                $rval = system("$sim -S $i -p $platform < $tmp_in > $tmp_out 2>&1");
                if ($rval == 0) {
                        print "$i -> success\n";
        } else {
                        print "$i -> FAILED, rval = $rval\n";
                        system("egrep ERROR $tmp_out");
                        print "Log file in $tmp_out\n";
                        return -1;
                }
        }
    return 0;
}

## Sprint
#print "*****************************************************\n";
#print "Running stress tests on SPRINT simulation platform...\n";
#if (run_sim("$build_dir/asic-sim", 3, 10, 100, "sprint") == -1) { exit; }
##if (run_sim("$build_dir/asic-sim-e", 3, 4, 200, "sprint") == -1) { exit; }
##if (run_sim("$build_dir/asic-sim-e", 17, 17, 2000, "sprint") == -1) { exit; }
#print "SPRINT stress tests completed SUCCESSFULLY\n";
#print "*****************************************************\n\n";



# Pulsar
#print "*****************************************************\n";
#print "Running stress tests on PULSAR simulation platform...\n";
#if (run_sim("$build_dir/asic-sim", 3, 10, 100, "pulsar") == -1) { exit; }
#if (run_sim("$build_dir/asic-sim-e", 3, 4, 200, "pulsar") == -1) { exit; }
#if (run_sim("$build_dir/asic-sim-e", 17, 17, 2000, "pulsar") == -1) { exit; }
#print "PULSAR stress tests completed SUCCESSFULLY\n";
#print "*****************************************************\n\n";


# Saturn
#print "*****************************************************\n";
#print "Running stress tests on SATURN simulation platform..."; 
#if (run_sim("$build_dir/asic-sim", 3, 10, 100, "saturn") == -1) { exit; }
## if (run_sim("$build_dir/asic-sim-e", 3, 4, 200, "saturn") == -1) { exit; }
## if (run_sim("$build_dir/asic-sim-e", 17, 17, 2000, "saturn") == -1) { exit; }
#print "SATURN stress tests completed SUCCESSFULLY\n";
#print "*****************************************************\n\n";

# Neptune
print "*****************************************************\n";
print "Running stress tests on NEPTUNE simulation platform...";
#if (run_sim("$build_dir/asic-sim", 3, 10, 100, "neptune") == -1) { exit; }
if (run_sim("$build_dir/asic-sim-e", 3, 4, 200, "neptune") == -1) { exit; }
if (run_sim("$build_dir/asic-sim-e", 17, 17, 2000, "neptune") == -1) { exit; }
print "NEPTUNE stress tests completed SUCCESSFULLY\n";
#=================================================================================



