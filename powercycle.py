#!/usr/bin/python

import sys
from powerCycle import SystemInfo,power_cycle_device

ip = "127.0.0.1"
type = "NOS"
name = "cli"
powerInfo = []
for arg in sys.argv[1:]:
	# powerInfo.append(":".split(arg)) # python 3
	try:
		powerIP, powerPorts = arg.split(":")
		pPortl = powerPorts.split(",")
		powerInfo.append([powerIP,pPortl])
	except ValueError:	
		print("Usage: <ip addr>:<power port>,[additional powerports] [additional ip addrs]:[more power ports]")
		sys.exit(0)

if (len(powerInfo)):
	sysInfo = SystemInfo(ip, type, name, powerInfo);
	print("Power cycle: ", sysInfo.power)

	rval = power_cycle_device(sysInfo);
	if (rval == None or rval == False):
		sys.stdout.write("Device power cycle not successfull\n")
		sys.exit(1)
	else:
		sys.stdout.write("Device power cycle completed\n")
		sys.exit(0)

