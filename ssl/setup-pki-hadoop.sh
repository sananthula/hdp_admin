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

# Title: setup-pki-hadoop.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script uses the Java keytool to create the files;
# host.key in the Java keystore. A host.crs is exported from the Java 
# keystore. This script uses the openssl tool and a local Self-Signed CA 
# to sign the csr files. Then the CA certificate is imported into the 
# keystore, this creates the root certificate. Then all of the host.crt 
# certificates are imported into every host keystore. Then the script 
# creates the Java truststore by importing the CA certificate. The script 
# then moves and renames all of the keystores into the correct hdp 
# security directory on all hosts. 
# NOTE: The Self-Signed CA must exist, it is not created by this script.
# First run the script to install the local Self-Signed CA.
# NOTE: This script relies up a list of the hosts containing a FQDN
# for each hosts. This file is defined in the variable HOSTS. 
# NOTE: Ensure the common name (CN) matches the FQDN domain of the
# server. The clients compares the CN with the DNS domain name
# to ensure that it is connecting to the correct server.
# NOTE: 
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
	LOGFILE=${LOGDIR}/setup-pki-hadoop-${DATETIME}.log
}

function callSSLFunction() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/ssl/ssl-functions.sh ]; then
                source ${HOME}/sbin/ssl/ssl-functions.sh
        else
                echo "ERROR: The file ssl-functions.sh not found."
        fi
}

function generateKey() {
# Use openssl to create a private key for every host in the cluster. 
# The output will be host.key in the working directory.
# NOTE: Openssl can generate both a private key and csr at the same time.

	for HOST in $(cat ${HOSTS}); do
		if [ -e "${WRKDIR}/${HOST}.jks" ]; then continue; fi
		echo "Create a private key for ${HOST}" | tee -a ${LOGFILE}
		openssl genrsa -out ${WRKDIR}/${HOST}.key 2048 >> ${LOGFILE} 2>&1
		checkFile ${WRKDIR}/${HOST}.key
	done
}

function generateCsr() {
# Use openssl to create a certificate signing request (.csr) for 
# every host in the cluster. The output will be host.csr in the 
# working directory.
# NOTE: Openssl can generate both a private key and csr at the same time.

	for HOST in $(cat ${HOSTS}); do
		if [ -e "${WRKDIR}/${HOST}.csr" ]; then continue; fi
		echo "Create a certificate signing request for ${HOST}" | tee -a ${LOGFILE}
                openssl req -key ${WRKDIR}/${HOST}.key -new -out ${WRKDIR}/${HOST}.csr  -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${UNIT}/CN=${HOST}" >> ${LOGFILE} 2>&1
		checkFile ${WRKDIR}/${HOST}.csr
	done
}

function generateCrt() {
# Use openssl to sign every certificate request with the Self-Signed CA 
# certficate file. The output will be node.crt in the working directory. 

	for HOST in $(cat ${HOSTS}); do
		if [ -e "${WRKDIR}/${HOST}.crt" ]; then continue; fi
        	echo "Signing a certificate for ${HOST}" | tee -a ${LOGFILE}
        	sudo openssl x509 -req -CA ${CADIR}/certs/ca.crt -CAkey ${CADIR}/private/ca.key -passin pass:${KEYPASS} -in ${WRKDIR}/${HOST}.csr -out ${WRKDIR}/${HOST}.crt -days 365 -CAcreateserial >> ${LOGFILE} 2>&1
		checkFile ${WRKDIR}/${HOST}.crt
	done
}

function validateCert() {
# Use openssl modulus to output serial numbers for the private and 
# public key. Then valididate that these two serial numbers match for 
# every node.

	echo
        for HOST in $(cat ${HOSTS}); do

		KEY=$(openssl rsa -noout -modulus -in ${WRKDIR}/${HOST}.key)
		CRT=$(openssl x509 -noout -modulus -in ${WRKDIR}/${HOST}.crt)

		if [ "${KEY}" == "${CRT}" ]; then
            		echo "The private key and public key pair validated on ${HOST}" | tee -a ${LOGFILE}
        	else
            		echo "!!!Failed validation of private key and public key pair for ${HOST}" | tee -a ${LOGFILE}
        	fi
	done
	
	echo -n "Did the keys validate? "
	checkContinue
}

function importCA() {
# Use keytool to import the root CA certificate file ca.crt. The self-signed 
# CA is the root certificate. This allows any additional certificates to be added
# to this keystore without confirmation. Ensure to use a matching alias.

	for HOST in $(cat ${HOSTS}); do
		echo "Import the CA crt into the keystore on ${HOST}" | tee -a ${LOGFILE}
		keytool -import -noprompt -keystore ${WRKDIR}/${HOST}.jks -storepass ${KEYSTOREPASS} -file ${CADIR}/certs/ca.crt -alias CARoot >> ${LOGFILE} 2>&1
	done
}

function importCrt() {
# Use keytool to import all of the node certificate files, node.crt, into
# every keystore. These follow on certificate files are called intermediate keys,
# together with the root key they form the trust chain. This will allow all nodes
# in the cluster to communicate with all of the other nodes. The output will be the 
# host keystore in the working directory.

	for HOST in $(cat ${HOSTS}); do
		echo "Import all of the hosts crt files into the keystore on ${HOST}" | tee -a ${LOGFILE}
		for CERT in $(cat ${HOSTS}); do
			keytool -import -noprompt -keystore ${WRKDIR}/${HOST}.jks -storepass ${KEYSTOREPASS} -file ${WRKDIR}/${HOST}.crt  -alias ${HOST} >> ${LOGFILE} 2>&1
		done
	done
}

function pushStore() {
# Move the keystores to appropriate security directories on every host. Change the 
# ownership to yarn, the group to hadoop, and permissions to 0440 on all keystores.


        for HOST in $(cat ${HOSTS}); do
                echo "Copy the node's keystore to ${HOST}" | tee -a ${LOGFILE}
                scp ${WRKDIR}/${HOST}.jks ${HOST}:${HOME}/keystore.jks >> ${LOGFILE} 2>&1
                ssh -tt ${HOST} -C "
                        sudo cp ${HOME}/keystore.jks ${SERVERSTORELOC};
                        sudo chown yarn:hadoop ${SERVERSTORELOC};
                        sudo chmod 0440 ${SERVERSTORELOC};
                        sudo cp ${HOME}/keystore.jks ${CLIENTSTORELOC};
                        sudo chown yarn:hadoop ${CLIENTSTORELOC};
                        sudo chmod 0440 ${CLIENTSTORELOC}
			sudo rm ${HOME}/keystore.jks;
                " >> ${LOGFILE} 2>&1
        done
}

function generateTrust() {
# Use the keytool to create a single truststore by importing the CA ca.crt file. The 
# output will be truststore.jks in the working directory.

	echo "Create truststore.jks" | tee -a ${LOGFILE}
	sudo keytool -import -noprompt -keystore ${WRKDIR}/truststore.jks -storepass ${TRUSTSTOREPASS} -file ${CADIR}/certs/ca.crt -alias CARoot >> ${LOGFILE} 2>&1
	checkFile ${WRKDIR}/truststore.jks
}

function pushTrust() {
# Move the truststore to the appropriate security directories. Change ownership to 
# yarn, the group to hadoop, and the permissions to 444 on all truststores.

        for HOST in $(cat ${HOSTS}); do
		echo "Copy the truststore to ${HOST}" | tee -a ${LOGFILE}
		scp ${WRKDIR}/truststore.jks ${HOST}:${HOME}/truststore.jks >> ${LOGFILE} 2>&1
		ssh -tt ${HOST} -C "
			sudo cp ${HOME}/truststore.jks ${SERVERTRUSTLOC};
			sudo chown yarn:hadoop ${SERVERTRUSTLOC};
			sudo chmod 0444 ${SERVERTRUSTLOC};
			sudo cp ${HOME}/truststore.jks ${CLIENTTRUSTLOC};
			sudo chown yarn:hadoop ${CLIENTTRUSTLOC};
			sudo chmod 0444 ${CLIENTTRUSTLOC};
			sudo rm ${HOME}/truststore.jks;
		" >> ${LOGFILE} 2>&1
	done
}

function listStore() {
# Optionally, add a listing of the keystores and truststore into the log file.

	echo -n  "List out the keystore and truststore to the logfile? "
	checkContinue

	for HOST in $(cat ${HOSTS}); do
		echo "Check the keystore on ${HOST}" | tee -a ${LOGFILE}
		keytool -list -v -keystore ${WRKDIR}/${HOST}-keystore.jks -storepass ${KEYSTOREPASS} >> ${LOGFILE} 2>&1
	done

	echo "Check the truststore on ${HOST}" | tee -a ${LOGFILE}
	keytool -list -v -keystore ${WRKDIR}/truststore.jks -storepass ${TRUSTSTOREPASS} >> ${LOGFILE} 2>&1
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
setCertVar
setPKIPass
createWrkDir
createSecurityDir

# Create certs
generateKey
generateCsr
generateCrt

# Import keystores
importCA
importCrt

# Validate Certs
validateCert

# Distribute keys
pushStore

# Create truststore
generateTrust

# Distribute truststores
pushTrust

# Validate
listStore

# Next steps 
validatePKI
