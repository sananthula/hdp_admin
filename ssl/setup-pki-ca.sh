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

# Title: setup-pki-ca.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script uses openssl to create the certificates and
# the keys for the Certificate Authority (CA). These are then 
# stored in the secure location of /etc/pki/CA. This is the default
# directory found in the openssl.cnf file.

# VARIABLE
NUMARGS=$#
HOST=$(hostname -f)

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
	LOGFILE=${LOGDIR}/setup-hdp-ca-${DATETIME}.log
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

function checkDir() {
# Test for the ${CADIR} directory

	if sudo test ! -e ${CADIR}; then
		echo "ERROR: The ${CADIR} directory does not exist." | tee -a ${LOGFILE}
	fi
}

function createIndex() {
# Test for index file, if present remove it and replace it

	# Test for the /etc/pki/CA/index.txt file
	if sudo test -e {CADIR}/index.txt; then
		sudo rm -f /etc/pki/CA/index.txt >> ${LOGFILE} 2>&1
	fi

	# Update the index and serial files
	echo "Create the CA index file on ${HOST}" | tee -a ${LOGFILE}
	sudo touch ${CADIR}/index.txt >> ${LOGFILE} 2>&1

	# Setup the serial file
	echo "Create the CA serial file on ${HOST}" | tee -a ${LOGFILE}
	sudo echo "1000" > /tmp/serial 
	sudo mv /tmp/serial ${CADIR}/serial 
}

function generateKey() {
# Create the private key for the CA. The output will be a  
# private key file, (ca.key) located in ${CADIR}/private.

	# Create the CA certificate and key
	if [ ! -e "${CADIR}/certs/ca.crt" ]; then
		echo "Create the CA key on ${HOST}" | tee -a ${LOGFILE}
		sudo openssl genrsa -out ${CADIR}/private/ca.key 2048 >> ${LOGFILE} 2>&1
	fi
}

function generateCrt() {
# The openssl command will create a Self-Signed certificate
# for the Certificate Authority. The output will be a cert 
# file, (ca.crt) located in ${CADIR}/certs. The certificate will 
# expire in 1 year (365 days).

	# Create the CA certificate
	if [ ! -e "${CADIR}/certs/ca.crt" ]; then
		echo "Create the CA certificate on ${HOST}" | tee -a ${LOGFILE}
		sudo openssl req -new -x509 -key ${CADIR}/private/ca.key -out ${CADIR}/certs/ca.crt -passin pass:${KEYPASS} -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${UNIT}/CN=${HOST}/emailAddress=${EMAIL}" -days 365 >> ${LOGFILE} 2>&1
	fi

	checkFile ${CADIR}/certs/ca.crt
}

function setPerm() {
# Set permissions on the ca.key file

	echo "Set ownership and permissons on certificate files" | tee -a ${LOGFILE}
	sudo chown root:root ${CADIR}/private/ca.key
	sudo chmod 0400 ${CADIR}/private/ca.key >> ${LOGFILE} 2>&1
	sudo chown root:root ${CADIR}/certs/ca.crt
	sudo chmod 0444 ${CADIR}/certs/ca.crt >> ${LOGFILE} 2>&1
}

function updateCACert {
# Update the Java default cacerts file
# Future update
        cp /etc/alternatives/java_sdk/jre/lib/security/cacerts ${WRKDIR}/cacerts
        for CERT in $(ls ${CADIR}/private); do
                keytool -importcert -noprompt -file ${CADIR}/certs/ca.crt -alias CARoot -keystore ${WRKDIR}/cacerts -storepass "changeit"
        done
}

function pushCACert {
# Move the cacert file to appropriate security directories on every node.
# Future update

        for HOST in $(cat ${HOSTS}); do
                echo "Copy the cacerts to ${HOST}" | tee -a ${LOGFILE}
                scp ${WRKDIR}/cacerts ${HOST}:${HOME}/cacerts >> ${LOGFILE} 2>&1
                ssh -tt ${HOST} -C sudo cp ${HOME}/cacerts /etc/alternatives/java_sdk/jre/lib/security/cacerts; >> ${LOGFILE} 2>&1
        done
}

function validateCA() {
# Steps to validate 

	echo
	echo "Validate"
	echo "1. Review the log file at ${LOGFILE}."
	echo "2. Check the ownership and permissions on the CA certificate."
	sudo ls -l ${CADIR}/certs/ca.crt ${CADIR}/private/ca.key ${CADIR}/serial
	echo "3. Test the CA certificate with the following command:"
	echo " sudo openssl x509 -in ${CADIR}/certs/ca.crt -noout -text" 
	echo
}

# MAIN
# Source functions
callFunction
callSSLFunction

# Run checks
checkSudo
checkArg 0

# Run setups
setupLog ${LOGFILE}
setCertVar

# Create CA
checkDir
createIndex
generateKey
generateCrt
setPerm

# Update cacerts
#updateCACert
#pushCACert

# Next steps
validateCA
