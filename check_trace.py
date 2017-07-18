#!/usr/local/bin/python
import re

#routef = open('/vobs/projects/springboard/fabos/src/sys/dev/asic/condor2/c2_route.c')
#rte_traces = [line.rstrip().split(' ') if re.match(r"rte_trace",line) for line in open('/vobs/projects/springboard/fabos/src/sys/dev/asic/condor2/c2_route.c')]

#rte_traces = [list(map(int, line.split(','))) for line in routef]

#for line in routef:
	#if re.match(r"rte_trace\((\d+)", line):
		#print(line)
#for line in rte_traces:
	#print(line)


print(m.group(0), line) for line in open('/vobs/projects/springboard/fabos/src/sys/dev/asic/condor2/c2_route.c') if m = re.match(r"rte_trace\((\d+)", line)
