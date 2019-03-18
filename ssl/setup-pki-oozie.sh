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

# Title: setup-pki-oozie.sh
# Author: Vladimir Zlatkin and WKD
# Date: 1MAR18
# Purpose: This script setups SSL encryption for Oozie. Oozie requires
# a unique certificate, it must consist of only the domain from the DNS
# of the cluster.
# Note: This script must be run on the Ambari server.
# Note: The setup for Hadoop SSL must be run first.

# VARIABLE
NUMARGS=$#
DOMAIN=$(hostname -d)

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
	LOGFILE=${LOGDIR}/setup-pki-oozie-${DATETIME}.log
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
# Test for domain name

	echo "Use Ambari to stop the Ooozie service."
	echo -n "The domain is set to ${DOMAIN}. "
	checkContinue
}

function setServer() {
# Set variable for either one or two Oozie masters, two masters 
# supports HA for Oozie.

	while : ; do
		echo "Enter the FQDN for the master. Press <ENTER> if none."
		read -p "Enter first oozie master: " OOZIE_ONE
		read -p "Enter second oozie master: " OOZIE_TWO
		OOZIE_SERVERS=$(echo ${OOZIE_ONE} " " ${OOZIE_TWO})	
		echo $OOZIE_SERVERS
		checkCorrect
	done
}

function createDomainKey() {
# Oozie requires a unique certificate, the name must consist of only the 
# domain from the DNS of the cluster. Generate a private key and a 
# csr for just the domain name of the cluster. The first output will be 
# domain.key in the working directory. Additionally generate a 
# certificate request. The second output will be a domain.csr in the 
# working directory.

    	if [ ! -e "${WRKDIR}/${DOMAIN}.crt" ]; then
 		echo "Create a private key and a csr for ${DOMAIN}" | tee -a ${LOGFILE}
        	sudo openssl req -new -newkey rsa:2048 -nodes -keyout ${WRKDIR}/${DOMAIN}.key -out ${WRKDIR}/${DOMAIN}.csr  -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${UNIT}/CN=*.${DOMAIN}" >> ${LOGFILE} 2>&1
	fi

	checkFile ${WRKDIR}/${DOMAIN}.key
	checkFile ${WRKDIR}/${DOMAIN}.csr
}

function createDomainCrt() {
# Generate a CA signed crt file for the domain name of the cluster.
# The output will be domain.crt in the working directory.

    	if [ ! -e "${WRKDIR}/${DOMAIN}.crt" ]; then
 		echo "Create a crt for ${DOMAIN}" | tee -a ${LOGFILE}
        	#sudo openssl ca -batch -cert ${CADIR}/certs/ca.crt -keyfile ${CADIR}/private/ca.key -infiles ${WRKDIR}/${DOMAIN}.csr -out ${WRKDIR}/${DOMAIN}.crt -startdate 20160101120000Z >> ${LOGFILE} 2>&1
        	sudo openssl x509 -req -CA ${CADIR}/certs/ca.crt -CAkey ${CADIR}/private/ca.key -passin pass:${KEYPASS} -in ${WRKDIR}/${DOMAIN}.csr -out ${WRKDIR}/${DOMAIN}.crt -days 365 >> ${LOGFILE} 2>&1

		checkFile ${WRKDIR}/${DOMAIN}.crt
    	fi
}

function createOozieKey() {
# Use openssl to use the CA signed crt file to create a private key 
# in the p12 format. The private key file output is oozie.p12 located 
# in the working directory. 

	echo "Create a private pkcs key for Oozie" | tee -a ${LOGFILE}
    	sudo openssl pkcs12 -export -CAfile ${CADIR}/certs/ca.crt -in ${WRKDIR}/${DOMAIN}.crt -inkey ${WRKDIR}/${DOMAIN}.key -out ${WRKDIR}/oozie.p12 -name tomcat -passout pass:${KEYPASS} -chain >> ${LOGFILE} 2>&1

	checkFile ${WRKDIR}/oozie.p12
}

function importOozieKey() {
# Add the P12 private key to Oozie JKS keystore to be used by Oozie master.


	for HOST in ${OOZIE_SERVERS}; do
		echo "Import the pkcs key for Oozie" | tee -a ${LOGFILE}
        	sudo keytool --importkeystore -noprompt -srckeystore ${WRKDIR}/oozie.p12 -srcstoretype PKCS12 -srcstorepass ${STOREPASS} -destkeystore ${WRKDIR}/oozie.${HOST}.keystore  -deststorepass ${STOREPASS} -destkeypass ${KEYPASS} -alias tomcat >> ${LOGFILE} 2>&1
	done
}

function moveOoozieKeystore() {
# Move just the Oozie keystores to the Oozie masters
# WKD Change the ownership and permissions of the Oozie keystore

	for HOST in ${OOZIE_SERVERS}; do
                echo "Copy the Oozie's keystore to ${HOST}" | tee -a ${LOGFILE}
                scp ${WRKDIR}/oozie.${HOST}.keystore.jks ${HOST}:${HOME}/oozie.keystore.jks 2>&1 ${LOGFILE}
                ssh -tt ${HOST} -C "
			sudo mv ${HOME}/oozie-keystore.jks /home/oozie/.keystore.jks;
                	sudo chown oozie:oozie /home/oozie/.keystore.jks;
                	sudo chmod 0400 oozie:oozie /home/oozie/.keystore.jks;
		" >> ${LOGFILE} 2>&1
wn
	done
}

function importKey() {
# Import the public key into all keystores for every node

    	for HOST in $(cat ${HOSTS}); do
                echo "Import the domain's certificate to ${HOST}" | tee -a ${LOGFILE}
       		sudo keytool -import -noprompt -keystore ${WRKDIR}/${HOST}-keystore.jks -storepass ${STORE_PASSWORD} -file {WRKDIR}/${DOMAIN}.crt -alias tomcat >> ${LOGFILE} 2>&1
    	done
}

function moveKeystore() {
# Move all node keystore to both security directories on every node.

        for HOST in $(cat ${HOSTS}); do
                echo "Copy the node's keystore to ${HOST}" | tee -a ${LOGFILE}
                scp ${WRKDIR}/${HOST}.keystore.jks ${HOST}:${HOME}/keystore.jks >> ${LOGFILE} 2>&1
                ssh -tt ${HOST} -C "
                        sudo cp ${HOME}/keystore.jks ${SECDIR}/serverKeys/keystore.jks;
                        sudo chown yarn:hadoop ${SECDIR}/serverKeys/keystore.jks;
                        sudo chmod 0440 ${SECDIR}/serverKeys/keystore.jks;
                        sudo mv ${HOME}/keystore.jks ${SECDIR}/clientKeys/keystore.jks;
                        sudo chown yarn:hadoop ${SECDIR}/clientKeys/keystore.jks;
                        sudo chmod 0440 ${SECDIR}/clientKeys/keystore.jks
                " >> ${LOGFILE} 2>&1
        done
}

# MAIN
# Source functions
callFunction
callSSLFunction

# Run checks
checkSudo
checkArg 0
checkAmbari
showIntro

# Run setups
setupLog
setPKIPass
setServer
setCertVar

# Create Domain CRT
createDomainKey
createDomainCrt

# Create Oozie keystore
createOozieKey
importOozieKey
moveOozieKeystore

# Import Oozie public key to Hadoop keystores
importKey

# Move Hadoop keystores
moveKeystore
