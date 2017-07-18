import os, sys, time;
import re;
import logging;
import csv;
import common.pexpect as pexpect;
import getpass;

class SystemInfo:
	ipAddr = "";
	type = "";
	name = "";
	power = [];

	def __init__(self, ip, type, name, power):
		self.ipAddr = ip;
		self.type = type;
		self.name = name;
		self.power = power;

class PowerCycleExpect (pexpect.spawn):
	powerIp = "";
	powerPorts = [];
	device = None;

	def __init__(self, device, powerIp, powerPorts, command, args=[], timeout=30, maxread=2000, searchwindowsize=None, logfile=None, cwd=None, env=None):
		self.device = device;
		self.powerIp = powerIp;
		self.powerPorts = powerPorts;
		pexpect.spawn.__init__(self, command, args, timeout, maxread, searchwindowsize, logfile, cwd, env);

	def getIp(self):
		return(self.device.ipAddr);
	
	def getPowerIp(self):
		return(self.powerIp);

	
# Expected header line columns:
expectedHdrLine = [
	"IP", "Name", "Type",
	"Power_1_IP", "Power_1_Outlets",
	"Power_2_IP", "Power_2_Outlets",
	"Power_3_IP", "Power_3_Outlets",
	"Power_4_IP", "Power_4_Outlets"
];

curr_user_name = "";

def print_help():
	sys.stdout.write("Displaying Help for %s\n" % (sys.argv[0]));
	sys.stdout.write("\n");
	sys.stdout.write(
		"This script is intended to simply power cycle a\n" \
		"single switch.  It uses the data from %s\n" \
		"to look up the power poles and associated outlets.\n" %
			(os.path.expanduser("~sbusch/scripts/data_files/brm_power.csv")));
	sys.stdout.write("\n");
	sys.stdout.write(
		"Warning: It turns off out outlets for the switch does not\n" \
		"attempt a clean shutdown first.\n");
	sys.stdout.write("\n");
	sys.stdout.write("Usage: %s <IP>\n" % (sys.argv[0]));
	sys.stdout.write("\n");
	sys.stdout.write(
		"A confirmation prompt is required before power cycling.\n");


# Try to get the user name for logging.
def getUserName():
	uName = os.environ['LOGNAME'];
	if (len(uName) > 0):
		return(uName);
	else:
		return("unk");


#
# parse_csv_power_data
#
# Returns a dictonary with a string key of the IP of the device and a
# SystemInfo object with the assocated data as the value.
#
def parse_csv_power_data(fName=os.path.expanduser("~sbusch/scripts/data_files/brm_power.csv")):

	# Open CSV reader
	fd = open(fName, "r");
	csvReader = csv.reader(fd, delimiter=",");
	if (csvReader == None):
		logging.error("Failed to open CSV file: %s" % (fName));
		return(None);
	
	# Validate Header line
	headerLine = csvReader.next();
	if (headerLine != expectedHdrLine):
		logging.error("Expected and File header columns do not match");
		logging.info("Expected: \"%s\"" % (expectedHdrLine));
		logging.info("File: \"%s\"" % (headerLine));
		return(None);

	# Loop over all lines
	allPower = {};
	lineCount = 0;
	lineNum = 1;  # Add 1 for header
	for line in csvReader:
		if (line == None):
			break;

		lineNum += 1;

		if (len(line) == 0):
			logging.warn("Empty line (line #%d)" % (lineNum));

		if (len(line) > len(expectedHdrLine)):
			logging.warn("Invalid line length (line #%d) -> skipping" % (lineNum));
			logging.debug("line = \"%s\" (%d)" % (line, len(line)));
			continue;

		ip = line[0];
		name = line[1];
		type = line[2];
		power = line[3:];

		if (len(power) % 2 != 0):
			logging.warn("Power information malformed for %s (line #%d) -> skipping" % (lineNum, ip));
			logging.debug("power = \"%s\"" % (power));
			continue;

		powerInfo = [];
		idx = iter(power);
		for val in idx:
			pIp = val;
			pOutlets = idx.next();

			# Skip all empties
			if (pIp == ""):
				continue;

			powerInfo.append((pIp, pOutlets.split(";")));

		sysInfo = SystemInfo(ip, type, name, powerInfo);
		allPower[ip] = sysInfo;
		lineCount += 1;
	
	logging.info("Parsed %d lines of the total %d lines (w/ header)" % (lineCount, lineNum));

	fd.close();

	if (len(allPower) == 0):
		logging.error("No power data parsed from file (%s)" % (fName));
		return(None);

	return(allPower);


def find_power_object(powerDB, key):
	if (not re.match("^([0-9]{1,3}\.){3}([0-9]{1,3})$", key)):
		logging.warn("Invalid key format.  Must be an IPv4 address: \"%s\"" % (key));
		return(None);
	
	if (powerDB.has_key(key)):
		return(powerDB[key]);
	else:
		logging.warn("Specified key not in known Power DB: \"%s\"" % (key));
		return(None);


def confirm_device(device):
	sys.stdout.write("Please confirm the correct device:\n");
	sys.stdout.write("  IP Address:    %s\n" % (device.ipAddr));
	sys.stdout.write("  Device Name:   %s\n" % (device.name));
	sys.stdout.write("  Device Type:   %s\n" % (device.type));
	sys.stdout.write("  Power Outlets: ");
	first = True;
	print(device.power)
	for power in device.power:
		powerStr = "";
		if (not first):
			powerStr = "                 ";

		powerStr += power[0] + " - " + ", ".join(power[1]) + "\n";
		sys.stdout.write(powerStr)
		first = False;
	
	retry = 0;
	while (retry < 3):
		ans = raw_input("Correct device identified? [Y(es)/N(o)] ");
		if (ans):
			ans.lower();
			if (ans == "y" or ans == "yes"):
				return(True);
			elif (ans == "n" or ans == "no"):
				return(False);
			else:
				sys.stdout.write("Invalid response: \"%s\"\n" % (ans));
		retry += 1;
	
	return(False);


def power_cycle_device(device):

	rc = True;
	power_poles = [];

	# Open power pole telnet sessions
	logging.info("Connecting to Power Poles");
	for power in device.power:
		pp_exp = __power_open_telnet(device, power[0], power[1]);

		if (not pp_exp):
			logging.error("(%s) Failure connecting to power pole" % (power[0]));
			rc = False
			break;

		power_poles.append(pp_exp);
	
	# If all power poles connected successfull, continue
	if (rc):
		rc = __power_cycle_driver(power_poles);

	# Close connctions
	for pp_exp in power_poles:
		pp_exp.sendline("quit");
		time.sleep(1);
		pp_exp.close();
	
	# Delete log files on success
	if (rc):
		logging.info("Cleaning up logging file");
		for pp_exp in power_poles:
			os.system("rm -f power_cycle_%s_%s.log" % (curr_user_name, pp_exp.getPowerIp().replace(".","_")));

	else:
		logging.warn("An error occurred at some point.  Please grab screen output and log files (power_cycle_%s_*.log) and send them to Scott. :)" % (curr_user_name));

	return(rc);


def __power_cycle_driver(power_poles):
	maxDelay = 0;

	# Get sessions to the right place for power operations
	for pp_exp in power_poles:
		if (not __power_change_directory(pp_exp)):
			logging.error("(%s) Failure during PP directory change" % (pp_exp.getPowerIp()));
			return(False);
	
	# Turn off all outlets
	logging.info("Turning outlets off");
	for pp_exp in power_poles:
		delay = __power_outlet_off(pp_exp);

		if (delay == -1):
			logging.warn("(%s) Failure turning off outlets -> aborting after partial operation" % (pp_exp.getPowerIp()));
			return(False);
		elif (delay > maxDelay):
			maxDelay = delay;

	if (maxDelay > 0):
		logging.info("Delaying for queued power off operations %d seconds" % (maxDelay + 10));
		time.sleep(maxDelay + 10);
	else:
		logging.info("Delaying for 10 seconds");
		time.sleep(10);
	
	maxDelay = 0;
	# Turn on all outlets
	logging.info("Turning outlets on");
	for pp_exp in power_poles:
		delay = __power_outlet_on(pp_exp);

		if (delay == -1):
			logging.warn("(%s) Failure turning on outlets -> aborting after partial operation" % (pp_exp.getPowerIp()));
			return(False);
		elif (delay > maxDelay):
			maxDelay = delay;

	if (maxDelay > 0):
		logging.info("Maximum power on delay is %d second(s)" % (maxDelay));

	return(True);


def __power_open_telnet(device, ip, ports, user="user", password="pass"):
	logging.debug("Connecting to power pole: %s" % (ip));

	log_fd = open("power_cycle_%s_%s.log" % (curr_user_name, ip.replace(".", "_")), "w");
	exp = PowerCycleExpect(device, ip, ports, "telnet %s" % (ip), logfile = log_fd);

	loginAttempts = 0;
	while (True):
		i = exp.expect(["login:", "Password:", "Connection closed by foreign host", "cli->", pexpect.TIMEOUT], timeout=10);
		if (i == 0):
			if (loginAttempts >= 3):
				logging.warn("(%s) Exceeded login attempts limit -> Failing" % (ip));
				return(None);

			exp.sendline(user);
			loginAttempts += 1;
		elif (i == 1):
			exp.sendline(password);
		elif (i == 2):
			logging.warn("(%s) Power pole telnet connection failed" % (ip));
			return(None);
		elif (i == 3):
			logging.debug("(%s) Login successful" % (ip));
			break;
		elif (i == 4):
			logging.warn("(%s) Timed out waiting for response" % (ip));
			return(None);
		else:
			logging.error("(%s) Unexpected pexpect pattern index during login" % (ip));
			return(None);
	
	return(exp);


def __power_change_directory(exp):
	
	logging.debug("(%s) Changing into power pole directory" % (exp.getPowerIp()));
	exp.sendline("cd access/");
	i = exp.expect(["cli->", pexpect.TIMEOUT], timeout=5);
	if (i == 1):
		logging.error("(%s) Failed to change to access/ directory" % (exp.getPowerIp()));
		return(False);
	
	exp.sendline("ls");
	i = exp.expect(["[\r\n](1[^/]+/)", pexpect.TIMEOUT], timeout=5);
	if (i != 0):
		logging.error("(%s) Failed getting nested directory" % (exp.getPowerIp()));
		return(False);
	
	dirName = exp.match.group(1);

	i = exp.expect(["cli->", pexpect.TIMEOUT], timeout=5);
	if (i == 1):
		logging.error("(%s) Failed listing access/ directory" % (exp.getPowerIp()));
		return(False);
	
	exp.sendline("cd %s" % (dirName));
	i = exp.expect(["cli->", pexpect.TIMEOUT], timeout=5);
	if (i == 1):
		logging.error("(%s) Failed changing to %s directory" % (exp.getPowerIp(), dirName));
		return(False);

	return(True);


def __power_outlet_off(exp):
	maxDelay = 0;

	logging.debug("(%s) Turning off outlets: %s" % (exp.getPowerIp(), exp.powerPorts));

	# During operations, requests may not complete immediately and we see this warning:
	# Warning: Command submitted but the response is pending. Complete operation may take about 30 seconds.
	for outlet in exp.powerPorts:
		logging.debug("Shutting off outlet: %s" % (outlet));
		exp.sendline("off %s" % (outlet));
		timeoutRetry  = 0;
		while (True):
			i = exp.expect(["(yes, no)", "Complete operation may take about ([0-9]+) seconds.", "Error: Invalid Target name:", "cli->", pexpect.TIMEOUT], timeout=10);
			if (i == 0):
				exp.sendline("yes");
			elif (i == 1):
				# Delayed operation
				delayTime = exp.match.group(1);
				logging.info("(%s) Power off operation queued.  Delay time = %s" % (exp.getPowerIp(), delayTime));

				if (int(delayTime) > maxDelay):
					logging.debug("(%s) New longest delay: %s, old: %d" % (exp.getPowerIp(), delayTime, maxDelay));
					maxDelay = int(delayTime);

			elif (i == 2):
				# "Error: Invalid Target name:"
				logging.error("(%s) Permissions issue! The specified port is not accessible from the user account. Please inform Scott so the problem can be fixed. :)" % (exp.getPowerIp()));
				return(-1);
			elif (i == 3):
				# "cli->"
				break;
			elif (i == 4):
				# Timeout
				timeoutRetry += 1;
				if (timeoutRetry > 3):
					logging.error("(%s) Exceeded timed out retries (%d) for powering off outlet (%s)" % (exp.getPowerIp(), timeoutRetry, outlet));
					return(-1);
				else:
					logging.warn("(%s) Timed out waiting for powering off outlet (%s) -> retrying" % (exp.getPowerIp(), outlet));

			else:
				logging.warn("(%s) Unexpected result while powering off outlet (%s)" % (exp.getPowerIp(), outlet));
				return(-1);

	if (maxDelay == 0):
		logging.debug("(%s) All outlets turned off" % (exp.getPowerIp()));
	else:
		logging.info("(%s) Maximum queue delay: %d" % (exp.getPowerIp(), maxDelay));

	return(maxDelay);


def __power_outlet_on(exp):
	maxDelay = 0;

	logging.debug("(%s) Turning on outlets: %s" % (exp.getPowerIp(), exp.powerPorts));

	# During operations, requests may not complete immediately and we see this warning:
	# Warning: Command submitted but the response is pending. Complete operation may take about 30 seconds.
	for outlet in exp.powerPorts:
		logging.debug("Turning on outlet: %s" % (outlet));
		exp.sendline("on %s" % (outlet));
		timeoutRetry = 0;
		while (True):
			i = exp.expect(["(yes, no)", "Complete operation may take about ([0-9]+) seconds.", "Error: Invalid Target name:", "cli->", pexpect.TIMEOUT], timeout=10);
			if (i == 0):
				exp.sendline("yes");
			elif (i == 1):
				# Delayed operation
				delayTime = exp.match.group(1);
				logging.info("(%s) Power on operation queued.  Delay time = %s" % (exp.getPowerIp(), delayTime));

				if (int(delayTime) > maxDelay):
					logging.debug("(%s) New longest delay: %s, old: %d" % (exp.getPowerIp(), delayTime, maxDelay));
					maxDelay = int(delayTime);

			elif (i == 2):
				# "Error: Invalid Target name:"
				logging.error("(%s) Permissions issue! The specified port is not accessible from the user account. Please inform Scott so the problem can be fixed. :)" % (exp.getPowerIp()));
				return(-1);
			elif (i == 3):
				# "cli->"
				break;
			elif (i == 4):
				# Timeout
				timeoutRetry += 1;
				if (timeoutRetry > 3):
					logging.error("(%s) Exceeded timed out retries (%d) for powering on outlet (%s)" % (exp.getPowerIp(), timeoutRetry, outlet));
					return(-1);
				else:
					logging.warn("(%s) Timed out waiting for powering on outlet (%s) -> retrying" % (exp.getPowerIp(), outlet));
			else:
				logging.warn("(%s) Unexpected result while powering on outlet (%s)" % (exp.getPowerIp(), outlet));
				return(-1);

	if (maxDelay == 0):
		logging.debug("(%s) All outlets turned on" % (exp.getPowerIp()));
	else:
		logging.info("(%s) Maximum queue delay: %d" % (exp.getPowerIp(), maxDelay));

	return(maxDelay);


if __name__ == "__main__":

	# logging.basicConfig(level=logging.DEBUG);
	logging.basicConfig(level=logging.INFO);

	if (len(sys.argv) != 2 or sys.argv[1].find("-") != -1):
		print_help();
		sys.exit(1);
	
	logging.info("Parsing data");

	powerDB = parse_csv_power_data();

	if (powerDB == None):
		logging.error("Failure parsing power data");
		sys.exit(1);
	
	device = find_power_object(powerDB, sys.argv[1]);
	if (not device):
		logging.error("The specified IP address not in Power DB: \"%s\"" % (sys.argv[1]));
		sys.exit(1);
	
	if (not confirm_device(device)):
		logging.error("Proper device confirmation failed -> Aborting");
		sys.exit(1);
	
	# Ready to power cycle
	uName = getUserName();
	curr_user_name = uName;
	logging.info("Captured User Name: %s" % (uName));

	rval = power_cycle_device(device);
	if (rval == None or rval == False):
		sys.stdout.write("Device power cycle not successfull\n");
		sys.exit(1);
	else:
		sys.stdout.write("Device power cycle completed\n");
		sys.exit(0);
	
	logging.critical("This message should never be reached");

