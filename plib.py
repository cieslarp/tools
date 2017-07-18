#!/usr/bin/python

#Library of useful python functions
import re
import sys
import locale
import subprocess
import logging

locale.setlocale(locale.LC_ALL, 'en_US')
debug_enabled=0

def log_init(logname):
	"""Initialize the logger

	"""
	global plog
	plog = logging.getLogger(logname)
	streamlog = logging.StreamHandler()
	streamlog.setLevel(logging.DEBUG)
	formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)-8s - %(message)s')
	streamlog.setFormatter(formatter)
	plog.addHandler(streamlog)
	plog.setLevel(logging.INFO)


def add_commas(num):
	"""Add commas to a number string in the appropriate places.
	
   	>>> print(add_commas(1234567890))
	1,234,567,890
   	>>> print("[ " + add_commas("1000") + " ]")
	[ 1,000 ]
   	>>> print(add_commas("12,500 already done"))
	12,500 already done
	"""
	nums=str(num)
	m=1
	#return '{:,}'.format(num) # works in new Python3.2
	while m:
		(nums, m) = re.subn(r"(\d)(\d\d\d)(?!\d)", r"\1,\2", nums, 1)
		#print "num{0} nums{1} m{2}".format(str(num), nums, m)
		#print "num:", num, "nums:", nums, "m:", m
	return nums

def add_commas_gen(num):
	"""Add commas to a number string in the appropriate places using locale.
	
   	>>> print add_commas(1234567890)
	1,234,567,890
   	>>> print "[", add_commas("1000"), "]"
	[ 1,000 ]
   	>>> print add_commas("12,500 already done")
	12,500 already done
	"""
	# Could also just use '{:,}'.format(12345) #however this does not seem to work
	return locale.format("%d", int(num), grouping=True)

def run(*cmds):
	"""Run a command and return the output.

	>>> print run("echo hi")
	hi
	<BLANKLINE>
	"""
	cmdlist = []
	for arg in cmds:
		for word in arg.split():
			#print "word:[" + word.strip(), "]"
			cmdlist.append(word.strip())
			#print cmdlist

	mycmd = subprocess.Popen(cmdlist, shell=False, stdout=subprocess.PIPE)
	return mycmd.communicate()[0]

def log(*to_log):
	"""Print a debug message if debugging is enabled.

	"""
	global plog
	#print to_log

	entries = []
	for p in to_log:
		entries.append(repr(p))

	#if not plog: log_init("plib")
	try:
		plog
	except NameError:
		log_init("plib")

	plog.debug(" ".join(entries))

def enable_debug_log():
	"""Enable debugging messages.

	"""
	global plog
	plog.setLevel(logging.DEBUG)
	log("debugging enabled!")



# Execute if library is called directly
if __name__ == "__main__":
	import doctest
	doctest.testmod()

	import profile
	#profile.run('doctest.testmod()')
