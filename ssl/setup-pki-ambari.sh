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

# Title: setup-pki-ambari.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This creates public-private key pairs for use by non-Java
# systems, such as Ambari. Which is written in Python. This script uses 
# the Java keytool to create the files; host.p12. It uses the previously
# signed host key in the Java keystore. Thus there is no need to sign it 
# again. The script then uses openssl to generate a .pem and a .key file 
# from the .p12 file. These are distributed to all security directories.
# NOTE: This script relies up a list of the hosts containing a FQDN
# for each hosts. This file is defined in the variable HOSTS. 

# VARIABLES
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
	LOGFILE=${LOGDIR}/setup-ssl-ambari-${DATETIME}.log
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

function generateP12() {
# Use keytool to create a keystore for every host in the cluster. 
# The output will be host.jks in the working directory.

	for HOST in $(cat ${HOSTS}); do
		if [ -e "${WRKDIR}/${HOST}.p12" ]; then continue; fi
		echo "Create the private key, p12 format, for ${HOST}" | tee -a ${LOGFILE}
#               keytool -importkeystore -srckeystore ${HOST}.jks -srcstorepass "${KEYSTOREPASS}" -srckeypass "${KEYPASS}" -srcalias ${HOST} -destkeystore ${HOST}.p12 -deststoretype PKCS12 -deststorepass "${KEYSTOREPASS}" -destkeypass "${KEYPASS}" >> ${LOGFILE} 2>&1
		openssl pkcs12 -export -in ${WRKDIR}/${HOST}.crt -inkey ${WRKDIR}/${HOST}.key -out ${WRKDIR}/${HOST}.p12 -name ${HOST} -passout pass:${KEYPASS} -CAfile ${CADIR}/certs/ca.crt -caname CARoot
		checkFile ${WRKDIR}/${HOST}.p12
	done
}

function generatePem {
# Create the PEM and private key file required by Ranger. 

	for HOST in $(cat ${HOSTS}); do
		if [ -e "${WRKDIR}/${HOST}.pem" ]; then continue; fi
                echo "Create the private pem file for Ranger" | tee -a ${LOGFILE}
    		openssl pkcs12 -in ${WRKDIR}/${HOST}.p12 -passin pass:${KEYPASS} -nokeys -out ${WRKDIR}/${HOST}.pem
  	done
}

function pushKey() {
# Move the keys to appropriate security directories on every host. 
# WARNING: This assumes you are running Ambari as non-root, you must change 
# ownership to ambari and the group to ambari. If not then the ownership
# and group should revert back to root:root. 

        for HOST in $(cat ${HOSTS}); do
		echo "Copy the host's keys to ${HOST}" | tee -a ${LOGFILE}
		scp ${WRKDIR}/${HOST}.key ${HOST}:${HOME}/server.key >> ${LOGFILE} 2>&1
		scp ${WRKDIR}/${HOST}.pem ${HOST}:${HOME}/server.pem >> ${LOGFILE} 2>&1
		ssh -tt ${HOST} -C "
			sudo cp ${HOME}/server.key ${SERVERDIR}/server.key;
			sudo chown ambari:ambari ${SERVERDIR}/server.key;
			sudo chmod 0440 ${SERVERDIR}/server.key;
			sudo cp ${HOME}/server.pem ${SERVERDIR}/server.pem;
			sudo chown ambari:ambari ${SERVERDIR}/server.pem;
			sudo chmod 0444 ${SERVERDIR}/server.pem;
			sudo mv ${HOME}/server.key ${CLIENTDIR}/client.key;
			sudo chown ambari:ambari ${CLIENTDIR}/client.key;
			sudo chmod 0440 ${SERVERDIR}/client.key;
			sudo mv ${HOME}/server.pem ${CLIENTDIR}/client.pem;
			sudo chown ambari:ambari ${CILENTDIR}/client.pem;
			sudo chmod 0444 ${CLIENTDIR}/client.pem;
		" >> ${LOGFILE} 2>&1
	done
}

function validatePKI() {
# Steps to validate 

	echo
	echo "Valdiate:"
	echo "1. Review the log file at ${LOGFILE}"
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
setPKIPass
createWrkDir
createSecurityDir

# Create certs
generateP12
generatePem

# Distribute keys
pushKey

# Next steps 
validatePKI
