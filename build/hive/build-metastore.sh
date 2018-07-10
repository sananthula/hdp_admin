#!/bin/bash

# setupmetastore.sh
# WKD Jun 30, 2015

# VARIABLES

myhost="$(hostname) "
wkdir=/home/hdadmin

# FUNCTIONS

checkRoot() {
# Test for user root.
	if [ "$(id -u)" != "0" ]; then
        	echo "ERROR: This script must be run using sudo" 1>&2
        	exit 1
	fi
}

intro() {
	read -p "Have you run createmetastore.sql? (Y/N) " ans
	if [[ $ans == "Y" || $ans == "y" ]]; then
		echo	
	else
		echo "ERROR: You must first run createmetastore.sql"
		exit 1 
	fi
}

installMetastore() {
# Command line to call for db schema to install metastore
	/usr/lib/hive/bin/schematool -dbType mysql -initSchema
}

postInstructions() {
# Post the instructions for after the build is completed.
	echo
	echo "***POST BUILD INSTRUCTIONS"
	echo
	echo "1. Login to mysql." 
	echo "2. Use metastore."
	echo "3. Show all tables."
}

# MAIN
checkRoot
intro
installMetastore
echo
echo "***"$myhost "completed " $0 
postInstructions
