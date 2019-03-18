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

# Title: setup-ssl-knox.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script setups SSL encryption for the Knox
# Gateway. The SSL setup is different from other ecosystem services.
# The commands for the setup are located on the Knox Gateway
# Server and must be run from the Knox Gateway host.
# WARNING: This script is a work in progress (WIP), do not use.
# WARNING: Much of the topology values are hardcoded. You will 
# have to edit them before using the LDAP setup.
# Note: This script must be run on the Ambari server.

# VARIABLE
NUMARGS=$#
GATEWAY=/usr/hdp/current/knox-server

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
                echo "ERROR: The file ${HOME}/sbin/functions.sh not found."
                echo "This required file provides supporting functions."
	fi
	LOGFILE=${LOGDIR}/setup-ssl-knox-${DATETIME}.log
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

function setServer() {
# Set variable for either one or two Knox Gateway servers, two servers 
# supports HA for Knox Gateway.

	if [ -z ${KNOX_SERVERS} ]; then	
		echo
		echo -n "IMPORTANT: Stop the Knox service before implementing SSL."
		pause
		echo
        	while : ; do
                	echo "Enter the FQDN for the servers. Press <ENTER> if none."
                	read -p "Enter the first Knox Gateway server: " KNOX_ONE
               		# read -p "Enter the second Knox Gateway server: " KNOX_TWO
			KNOX_SERVERS=$(echo ${KNOX_ONE} " " ${KNOX_TWO})
                	echo -n "The Knox Gateway servers are: ${KNOX_SERVERS}"
                	checkCorrect
        	done
	fi
}

function createCert() {
# Create a cert for Knox Gateway, this must be done on each Knox Gateway server

	echo "Create the certificate for Knox Gateway" | tee -a ${LOGFILE}	
	ssh -tt ${KNOX_ONE} -C "sudo ${GATEWAY}/bin/knoxcli.sh create-cert --hostname ${KNOX_ONE}" >> ${LOGFILE} 2>&1

	#if [ -z ${KNOX_TWO} ]; then
	#	ssh -tt ${KNOX_TWO} -C "sudo ${GATEWAY}/bin/knoxcli.sh create-cert --hostname ${KNOX_TWO}" >> ${LOGFILE} 2>&1
	#fi
}

function moveCert() {
# Copy the cert back to Ambari ${WRKDIR} directory.

	echo "Copy the certificate from the Knox Gateway" | tee -a ${LOGFILE}	
	ssh -tt ${KNOX_ONE} -C "sudo cp ${GATEWAY}/data/security/keystores/gateway.jks /tmp" >> ${LOGFILE} 2>&1
	scp ${KNOX_ONE}:/tmp/gateway.jks ${WRKDIR}/gateway.jks >> ${LOGFILE} 2>&1
	ssh -tt ${KNOX_ONE} -C "sudo rm /tmp/gateway.jks"  >> ${LOGFILE} 2>&1
	checkFile ${WRKDIR}/gateway.jks >> ${LOGFILE} 2>&1
pause
	#if [ -z ${KNOX_TWO} ]; then
	#scp ${KNOX_TWO}:${GATEWAY}/data/security/keystores/gateway.jks ${WRKDIR}/ssl/gateway-two.jks >> ${LOGFILE} 2>&1
	#fi
}

function exportCert() {
# Use the keytool to export the gateway.crt file from the gateway.

	echo "IMPORTANT: Press <ENTER>"		
	sudo keytool -export -rfc -keystore ${WRKDIR}/gateway.jks -file ${WRKDIR}/gateway.crt -alias gateway-identity >> ${LOGFILE} 2>&1
	checkFile ${WRKDIR}/gateway.crt >> ${LOGFILE} 2>&1
}

function importTruststore() {
# Use the keytool to import the gateway.crt file. 

        echo "Import the gateway.crt file into the truststore" | tee -a ${LOGFILE}
        sudo keytool -import -noprompt -keystore ${WRKDIR}/all.jks -storepass ${STORE_PASSWORD} -file ${WRKDIR}/gateway.crt -alias gateway-identity >> ${LOGFILE} 2>&1
}

function moveTruststore() {
# Move the truststore to the appropriate security directories. Change ownership to
# yarn, the group to hadoop, and the permissions to 444 on all truststores.

        for HOST in $(cat ${HOSTS}); do
                echo "Copy the truststore to ${HOST}" | tee -a ${LOGFILE}
                scp ${WRKDIR}/all.jks ${HOST}:${HOME}/all.jks >> ${LOGFILE} 2>&1
                ssh -tt ${HOST} -C "
                        sudo cp ${HOME}/all.jks ${SECDIR}/serverKeys/all.jks;
                        sudo chown -R yarn:hadoop ${SECDIR}/serverKeys;
                        sudo chmod 0444 ${SECDIR}/serverKeys/all.jks;
                        sudo mv ${HOME}/all.jks ${SECDIR}/clientKeys/all.jks;
                        sudo chown -R yarn:hadoop ${SECDIR}/clientKeys;
                        sudo chmod 0444 ${SECDIR}/clientKeys/all.jks
                " >> ${LOGFILE} 2>&1
        done
}

function validateKnox() {
# Steps to validate

        echo
        echo "Validate"
        echo "1. Review the log file at ${LOGFILE}."
        echo "2. Test by using Ambari to restart the Knox Gateway server."
	echo "3. Test from the Ambari server with the curl command."
	echo "    curl --cacert ${SECDIR}/clientKeys/all.jks -u sales1:BadPass#1 https://${KNOX_ONE}:8443/gateway/${CLUSTER}/webhdfs/v1?op=GETHOMEDIRECTORY"
	echo
	echo "Syntax: curl --cacert $certificate_path -u $username:$password https:// $gateway-hostname:$gateway_port/gateway/$cluster_name/webhdfs/v1?op=GETHOMEDIRECTORY"
        echo
}

# MAIN
# Source functions
callFunction
callSSLFunction

# Run checks
checkSudo
checkArg 0
checkAmbari

# Run setups
setupLog ${LOGFILE}
setSSLPassword
setServer

# Run
createCert
moveCert
exportCert
importTruststore
moveTruststore

# Validate
validateKnox
