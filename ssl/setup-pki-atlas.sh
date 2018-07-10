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

# Title: setup-pki-atlas.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script uses the Java keytool to create the files;
# host.key, host.csr, and host.crt from the Java keystore. This script 
# uses the openssl tool and a local Self-Signed CA to sign the csr files. 
# Then the CA certificate is imported into the keystore, this creates the 
# root certificate. Then all of the host.crt certificates are imported into 
# every host keystore. Then the script creates the Java truststore by 
# importing the CA certificate. The script then moves and renames all of 
# the keystores into the correct hdp security directory on all hosts. 
# NOTE: The Self-Signed CA must exist, it is not created by this script.
# First run the script to install the local Self-Signed CA.
# NOTE: This script relies up a list of the hosts containing a FQDN
# for each hosts. This file is defined in the variable HOSTS. 
# NOTE: Ensure the common name (CN) matches the FQDN domain of the
# server. The clients compares the CN with the DNS domain name
# to ensure that it is connecting to the correct server.
# NOTE: We have replaced the two directories called for in HWX docs with 
# a single directory, /etc/security/pki.

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
	LOGFILE=${LOGDIR}/setup-pki-atlas-${DATETIME}.log
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

function runAtlas {
# Create creditentials for Atlas

	if [ -f /usr/hdp/current/atlas-server/bin/cputils.py ]; then
		echo -e "\n###########\nCreating Atlas credential store. For the provider input jceks://file$(pwd)creds.jceks. \n Use the same keystore and truststore passwords\n###########\n"
  		/usr/hdp/current/atlas-server/bin/cputils.py
	fi
}

function pushKey() {
# Move the keys to appropriate security directories on every node. Change the 
# ownership to yarn, the group to hadoop, and permissions to 440 on all keystores.

        for HOST in $(cat ${HOSTS}); do
		echo "Copy the Atlas's keys to ${HOST}" | tee -a ${LOGFILE}
		scp ${WRKDIR}/creds.jceks ${HOST}:${HOME}/creds.jceks >> ${LOGFILE} 2>&1
		ssh -tt ${HOST} -C "
			sudo cp ${HOME}/creds.jceks ${SECDIR}/creds.jceks;
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

# Run Atlas
runAtlas

# Distribute keys
pushKey

# Next steps 
validatePKI
