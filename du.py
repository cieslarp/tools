#!/usr/bin/python

import sys
import plib

Args=[]

for arg in sys.argv[1:]:
	import re
	plib.log("pre-ARG:", arg)
	m = re.search('(?<=-)\w+', arg)
	plib.log("arg(", arg, ") m(", m, ")")
	if m:
		if m.group(0).isdigit():
		    arg = "--max-depth=" + m.group(0)
		    plib.log("postARG:", arg)
		if m.group(0) in 'd':
			plib.enable_debug_log()
			arg = ""
	Args.append(arg)

plib.log(sys.argv)
plib.log(Args)

Du = plib.run("/usr/bin/du --bytes", " ".join(Args)).split("\n")
dud = {}
for dul in Du:
	duls = dul.strip()
	if len(duls) > 0:
		size, name = duls.split()
		plib.log("name(", name, ") size(", size, ")")
		dud[name] = int(size)
	
plib.log("dud{", dud, "}")

for name, size in sorted(dud.iteritems(), key=lambda (k,v): (v,k)):
	print plib.add_commas(size).rjust(14), name
