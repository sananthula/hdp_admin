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

# Title: setup-pki-ranger.sh
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
	LOGFILE=${LOGDIR}/setup-pki-ranger-${DATETIME}.log
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

function generateKey() {
# Use openssl to create a private key for every host in the cluster. 
# The output will be host.key in the working directory.
# NOTE: Openssl can generate both a private key and csr at the same time.

	echo "Create a private key for ${ALIAS}" | tee -a ${LOGFILE}
	openssl genrsa -out ${WRKDIR}/${ALIAS}.key 2048 >> ${LOGFILE} 2>&1
	checkFile ${WRKDIR}/${ALIAS}.key
}

function generateCsr() {
# Use openssl to create a certificate signing request (.csr) for 
# every host in the cluster. The output will be host.csr in the 
# working directory.
# NOTE: Openssl can generate both a private key and csr at the same time.

	echo "Create a certificate signing request for ${ALIAS}" | tee -a ${LOGFILE}
        openssl req -key ${WRKDIR}/${ALIAS}.key -new -out ${WRKDIR}/${ALIAS}.csr  -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${UNIT}/CN=${ALIAS}" >> ${LOGFILE} 2>&1
	checkFile ${WRKDIR}/${ALIAS}.csr
}

function generateCrt() {
# Use openssl to sign every certificate request with the Self-Signed CA 
# certficate file. The output will be node.crt in the working directory. 

       	echo "Signing a certificate for ${ALIAS}" | tee -a ${LOGFILE}
       	sudo openssl x509 -req -CA ${CADIR}/certs/ca.crt -CAkey ${CADIR}/private/ca.key -passin pass:${KEYPASS} -in ${WRKDIR}/${ALIAS}.csr -out ${WRKDIR}/${ALIAS}.crt -days 365 -CAcreateserial >> ${LOGFILE} 2>&1
	checkFile ${WRKDIR}/${ALIAS}.crt
}

function validateCert() {
# Use openssl modulus to output serial numbers for the private and 
# public key. Then valididate that these two serial numbers match for 
# every node.

	echo
	KEY=$(openssl rsa -noout -modulus -in ${WRKDIR}/${ALIAS}.key)
	CRT=$(openssl x509 -noout -modulus -in ${WRKDIR}/${ALIAS}.crt)

	if [ "${KEY}" == "${CRT}" ]; then
        	echo "The private key and public key pair validated on ${ALIAS}" | tee -a ${LOGFILE}
        else
        	echo "!!!Failed validation of private key and public key pair for ${ALIAS}" | tee -a ${LOGFILE}
		exit
        fi
}

function importCA() {
# Use keytool to import the root CA certificate file ca.crt. The self-signed 
# CA is the root certificate. This allows any additional certificates to be added
# to this keystore without confirmation. Ensure to use a matching alias.

	echo "Import the CA crt into the keystore on ${ALIAS}" | tee -a ${LOGFILE}
	keytool -import -noprompt -keystore ${WRKDIR}/${STORE} -storepass ${KEYSTOREPASS} -file ${CADIR}/certs/ca.crt -alias CARoot >> ${LOGFILE} 2>&1
}

function importCrt() {
# Use keytool to import all of the node certificate files, node.crt, into
# every keystore. These follow on certificate files are called intermediate keys,
# together with the root key they form the trust chain. This will allow all nodes
# in the cluster to communicate with all of the other nodes. The output will be the 
# host keystore in the working directory.

	echo "Import the crt file into the keystore on ${ALIAS}" | tee -a ${LOGFILE}
	keytool -import -noprompt -keystore ${WRKDIR}/${STORE} -storepass ${KEYSTOREPASS} -file ${WRKDIR}/${ALIAS}.crt  -alias ${ALIAS} >> ${LOGFILE} 2>&1
}

function pushStore() {
# Move the keystores to appropriate security directories on every host. Change the 
# ownership to yarn, the group to hadoop, and permissions to 0440 on all keystores.
	HOSTS=$(echo "${HOST1}" " ${HOST2}")

        for HOST in $(cat ${HOSTS}); do
                echo "Copy the Ranger's keystore to ${HOST}" | tee -a ${LOGFILE}
                scp ${WRKDIR}/${STORE} ${HOST}:${HOME}/${STORE} >> ${LOGFILE} 2>&1
                ssh -tt ${HOST} -C "
                        sudo mv ${HOME}/${STORE} ${LOC}/${STORE};
                        sudo chown ${SERVICE}:${SERVICE} ${LOC}/${STORE};
                        sudo chmod 0440 ${LOC}/${STORE};
                " >> ${LOGFILE} 2>&1
        done
}

function generateTrust() {
# Use the keytool to create a single truststore by importing the CA ca.crt file. The 
# output will be truststore.jks in the working directory.

	echo "Create Ranger truststore.jks" | tee -a ${LOGFILE}
	sudo keytool -import -noprompt -keystore ${WRKDIR}/ranger-truststore.jks -storepass ${TRUSTSTOREPASS} -file ${CADIR}/certs/ca.crt -alias CARoot >> ${LOGFILE} 2>&1
	checkFile ${WRKDIR}/truststore.jks
}

function importTrust() {
# Import the Ranger admin cert into the Ranger truststore.
# WKD fix password
	
	echo "Create Ranger cert and import into the Ranger truststore" | tee -a ${LOGFILE}
	keytool -export -keystore ${WRKDIR}/ranger-admin-keystore.jks -alias rangeradmin -storepass ${KEYPASS} -file ${WRKDIR}/ranger-admin-trust.crt
	keytool -import -file ${WRKDIR}/ranger-admin-trust.crt -alias rangeradmintrust -keystore ${WRKDIR}/ranger-truststore.jks -storepass ${TRUSTSTOREPASS} 
}

function pushTrust() {
# Move the truststore to the appropriate security directories. Change ownership to 
# ranger, the group to ranger, and the permissions to 444 on all truststores.

        for HOST in $(cat ${HOSTS}); do
		echo "Copy the Ranger truststore to ${HOST}" | tee -a ${LOGFILE}
		scp ${WRKDIR}/ranger-truststore.jks ${HOST}:${HOME}/ranger-truststore.jks >> ${LOGFILE} 2>&1
		ssh -tt ${HOST} -C "
			sudo mv ${HOME}/ranger-truststore.jks ${RANGERTRUSTLOC};
			sudo chown ranger:ranger ${RANGERTRUSTLOC};
			sudo chmod 0444 ${RANGERTRUSTLOC};
		" >> ${LOGFILE} 2>&1
	done
}

function runRanger() {
# Loop to generate all of the keystores for Ranager.

	checkFile  ${RANGERCONFIG}

	while IFS=, read -r f1 f2 f3 f4 f5 f6; do

		# Set variables
		SERVICE=${f1}
		ALIAS=${f2}
		STORE=${f3}
		LOC=${f4}
		HOST1=${f5}
		HOST2=${f6}	

		# Create certs
		if [ -e "${WRKDIR}/${ALIAS}.key" ]; then continue; fi
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

	done < ${RANGERCONFIG}
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

# Run Ranger loop
runRanger

# Create truststore
generateTrust
importTrust

# Distribute truststores
pushTrust

# Next steps 
validatePKI
