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

# Title: clean-ssl.sh
# Author: WKD
# Date: 1MAR18 
# Purpose: Script to remove and clean up an install of the Java keystore
# and the Hadoop Keystore Factory.

# VARIABLE
NUMARGS=$#

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
                echo "ERROR: The file ssl-functions not found."
                echo "This required file provides supporting functions."
        fi
}

function showIntro() {
# Intro

	echo "********************************************************"
	echo "*         WARNING      WARNING      WARNING            *"
	echo "* This script will delete all files and directories    *"
	echo "* related to SSL. The best practice is to stop both    *"
	echo "* the cluster and Ambari before continuing.            *"
	echo "********************************************************"
	checkContinue
}

function cleanCA() {
# Delete the CA cert and key 
	
	if [ -e ${CADIR}/certs/ca.crt ]; then
		sudo rm -r -f ${CADIR}/private/ca.key
		sudo rm -r -f ${CADIR}/certs/ca.crt
		sudo rm -r -f ${CADIR}/certs/ca.srl
		sudo rm -r -f ${CADIR}/index.txt
		sudo rm -r -f ${CADIR}/serial

		echo "Remove ${CADIR}/private/ca.key"
		echo "Remove ${CADIR}/certs/ca.crt"
		echo "Remove ${CADIR}/certs/ca.srl"
		echo "Remove ${CADIR}/index.txt"
		echo "Remove ${CADIR}/serial"
	fi
}

function cleanAmbari() {
# Delete the Ambari cert and key

	if [ -e /etc/pki/tls/certs/ambari.crt ]; then 
 		sudo rm -r -f /etc/pki/tls/private/ambari.key
        	sudo rm -r -f /etc/pki/tls/certs/ambari.crt
        	sudo rm -r -f /var/lib/ambari-server/keys/cacerts.jks

        	echo "Remove /etc/pki/tls/private/ambari.key"
        	echo "Remove /etc/pki/tls/certs/ambari.crt"
        	echo "Remove /var/lib/ambari-server/keys/cacerts.jks"
	fi
}

function cleanDir() {
# Delete the jks directory and contents

	if [ -e ${HOME}/pki ]; then
        	sudo rm -r -f ${HOME}/pki
        	echo "Remove ${HOME}/pki"
	fi

        for HOST in $(cat ${HOSTS}); do
		if [ ! -e /etc/security/serverKeys ]; then break; fi

                echo "Deleting /etc/security/serverKeys on ${HOST}"
                ssh -tt ${HOST} -C "sudo rm -r -f /etc/security/serverKeys"
                echo "Deleting /etc/security/clientKeys on ${HOST}"
                ssh -tt ${HOST} -C "sudo rm -r -f /etc/security/clientKeys"
        done
}

function cleanRanger() {
# Clean ranger keys
# This is not elegant but it will get the job done.

	for HOST in $(cat ${HOSTS}); do
		ssh -tt ${HOST} "
			sudo rm /etc/ranger/admin/conf/ranger-admin-keystore.jks 2>/dev/null;
			sudo rm /etc/hadoop/conf/ranger-hbase-plugin-keystore.jks 2>/dev/null;
			sudo rm /etc/hadoop/conf/ranger-hdfs-plugin-keystore.jks 2>/dev/null
		"
	done
}

# MAIN
# Source functions
callFunction
callSSLFunction

# Run checks
checkSudo
checkArg 0
showIntro

# Run clean
cleanCA
cleanAmbari
cleanDir
cleanRanger
