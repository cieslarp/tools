#!/bin/sh

if [ $# -ne 1 ]
then
	echo "Usage: genlicense wwn"
	exit 1
fi
wwn=$1

echo "########################################"
echo "#"
echo "# Feature ID for License generation:"
echo "#"
echo "# Web Tool                  1"
echo "# Zoning                    2"
echo "# DMM Basic                 3"
echo "# DMM Enhanced              4"
echo "# Fabric                    5"
echo "# Remote SW                 6"
echo "# SAN-CM Basic (not in use) 7"
echo "# Extended Fabric           8"
echo "# Entry                     9"
echo "# Fabric Watch              10"
echo "# Perf Mon                  11"
echo "# Trunking                  12"
echo "# Security                  13"
echo "# 4 Domain                  14"
echo "# FICON CUP                 15"
echo "# NPIV                      16"
echo "# FCIP                      17"
echo "# POD-1                     18"
echo "# 2 Domain Fabric           19"
echo "# FCR (only for Xpath)      20"
echo "# POD-2                     21"
echo "# SAS                       22"
echo "########################################"
for x in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22
do
	license=`/users/home25/rlau/bin/lgen -f $x $wwn`
	echo "licenseadd \"$license\""
done

########################################
#
# Feature ID for License generation:
#
# Web Tool				1
# Zoning				2
# SE					3
# QLoop		 			4
# Fabric	 			5
# Remote SW	 			6
# Remote Fab 			7
# Extended	 			8
# Entry		 			9
# FW					10
# Perf Mon				11
# Trunking				12
# Security				13
# 4 Domain				14
# FICON CUP				15
# NPIV					16
# FCIP					17
# POD-1					18
# 2 Domain Fabric		19
# FCR (only for Xpath)	20
# POD-2					21
# SAS					22
########################################

