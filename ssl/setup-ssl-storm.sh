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

# Title: setup-ssl-storm.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script setups Storm SSL encryption.
# Note: This script must be run on the Ambari server.
# Note: The CA install script and the setup for SSL JKS must be run first.

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
	LOGFILE=${LOGDIR}/setup-ssl-storm-${DATETIME}.log
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

function stopService() {
# Stop Storm services

        echo -n "IMPORTANT: Use Ambari to stop all Storm services. "
        checkContinue
}

function configAmbari() {
# Required configurations changes for Ambari. Most of these should
# be left at the default. Change these only after careful research.

	echo "Set Storm properties and values in Ambari." | tee -a ${LOGFILE}
	
cat <<EOF | setAmbari 
      	storm-site ui.https.key.password ${KEYPASS},
   	storm-site ui.https.keystore.path ${KEYSTORELOC},
      	storm-site ui.https.keystore.password ${KEYSTOREPASS},
      	storm-site ui.https.keystore.type jks,
      	storm-site ui.https.port 8740,
    	ranger-storm-security ranger.plugin.storm.policy.rest.url ${RANGERURL},
    	ranger-storm-policymgr-ssl xasecure.policymgr.clientssl.keystore ${RANGERKEYSTORELOC},
      	ranger-storm-policymgr-ssl xasecure.policymgr.clientssl.keystore.password ${KEYSTOREPASS},
      	ranger-storm-policymgr-ssl xasecure.policymgr.clientssl.truststore ${TRUSTSTORELOC},
      	ranger-storm-policymgr-ssl xasecure.policymgr.clientssl.truststore.password ${TRUSTSTOREPASS},
    	ranger-storm-plugin-properties common.name.for.certificate ${RANGERCOMMONNAME}
EOF
}

function validateSSL() {
# Steps to validate

	echo
	echo "Validate:"
	echo "1. Review the log file at ${LOGFILE}."
	echo "2. Test by using Ambari to restart the Storm services."
	echo 
}

# MAIN
# Source functions
callFunction

# Run checks 
checkSudo
checkArg 0
checkAmbari
stopService

# Run setups
setupLog ${LOGFILE}
setPKIPass

# Config Ambari
configAmbari
cleanupAmbari

# Next steps
validateSSL
