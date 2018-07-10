#!/bin/bash

# Hortonworks University
# This script is for training purposes only and is to be used only
# in support of approved Hortonworks University exercises. Hortonworks
# assumes no liability for use outside of our traning environments.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Title: run-ssl.sh
# Author: WKD
# Date: 24JAN18
# Purpose: This is the front end script for enabling SSL
# encryption for a HDP cluster.

# VARIABLE
NUMARGS=$#
SSLDIR=${HOME}/sbin/ssl

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0)" 
        exit 
}

function callFunction() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/functions.sh ]; then
                source ${HOME}/sbin/functions.sh
        else
                echo "ERROR: The file ${HOME}/sbin/functions not found."
                echo "This required file provides supporting functions."
	fi
}

function callSSLFunction() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/ssl/ssl-functions.sh ]; then
                source ${HOME}/sbin/ssl/ssl-functions.sh
        else
                echo "ERROR: The file ssl-functions.sh not found."
        fi
}

function showMenu() {
	clear
	headingSSL

	echo "  
 1. Setup SSL for HDFS 
 2. Setup SSL for YARN 
 3. Setup SSL for Python
 4. Setup SSL for Hive
 5. Setup SSL for Oozie 
 6. Setup SSL for HBase 
 7. Setup SSL for Spark
 8. Setup SSL for Zeppelin
 9. Setup SSL for NiFi
 10. Setup SSL for Kafka
 11. Setup SSL for Storm
 12. Setup SSL for Atlas
 13. Setup SSL for Ranger
 14. Setup SSL for Ranger KMS
 15. Setup LDAP for Knox Gateway
 16. Setup SSL for Knox Gateway

"
	read -p "Enter your selection (q to quit): " OPTION junk
	
	# If there is an empty OPTION (Pressing ENTER) redisplays
	[ "${OPTION}" = "" ] && continue
}

function runOption() {
 	case $OPTION in
		1) ${SSLDIR}/setup-ssl-hdfs.sh
			;;
		2) ${SSLDIR}/setup-ssl-yarn.sh
			;;
		3) ${SSLDIR}/setup-ssl-python.sh
			;;
		4) ${SSLDIR}/setup-ssl-hive.sh
			;;
		5) ${SSLDIR}/setup-ssl-oozie.sh
			;;
		6) ${SSLDIR}/setup-ssl-hbase.sh
			;;
		7) ${SSLDIR}/setup-ssl-spark.sh
	   		;;
		8) ${SSLDIR}/setup-ssl-zeppelin.sh
			;;
		9) ${SSLDIR}/setup-ssl-nifi.sh
			;;
		10) ${SSLDIR}/setup-ssl-kafka.sh
			;;
		11) ${SSLDIR}/setup-ssl-storm.sh
			;;
		12) ${SSLDIR}/setup-ssl-atlas.sh
			;;
		13) ${SSLDIR}/setup-ssl-ranger.sh
			;;
		14) ${SSLDIR}/setup-ssl-kms.sh
			;;
		15) ${SSLDIR}/setup-ldap-knox.sh
			;;
		16) ${SSLDIR}/setup-ssl-knox.sh
			;;
		q*|Q*) clear; 
		       quit 0
			;;
		*) echo "Incorrect entry, please try again"
			;;
        esac
}

function runMenu() {

	while true; do
		showMenu
		runOption
		pause
	done
}

# MAIN
# Source functions
callFunction
callSSLFunction

# Run checks
checkSudo
checkArg 0

# Set Variables
clear
headingSSL
setPKIPass
clear
headingSSL
setAmbariVar

# Run menu
runMenu
