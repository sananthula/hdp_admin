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

# Title: setup-ssl-kms.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script setups Ranger KMS SSL encryption
# Note: This script must be run on the Ambari server.
# Note: The CA install script and the setup for SSL must be run first.

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
                echo "ERROR: The file ${HOME}/sbin/functions.sh not found."
                echo "This required file provides supporting functions."
	fi
	LOGFILE=${LOGDIR}/setup-ssl-kms-${DATETIME}.log
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
# Stop KMS services

        echo -n "IMPORTANT: Use Ambari to stop all KMS services. "
        checkContinue
}

function configAmbari() {
# Configure the Ambari server for Ranger KMS service
# The kms_port must match the ranger.service.https.port 6182

         echo "Set Ranger KMS properties and values in Ambari." | tee -a ${LOGFILE} 

cat <<EOF | setAmbari
        ranger-kms-site ranger.https.attrib.keystore.file ${RANGERKMSKEYSTORE},
        ranger-kms-site ranger.service.https.attrib.client.auth want,
        ranger-kms-site ranger.service.https.attrib.clientAuth   false,
        ranger-kms-site  ranger.service.https.attrib.keystore.file ${RANGERKMSKEYSTORE},
        ranger-kms-site ranger.service.https.attrib.keystore.keyalias gateway-identity,
        ranger-kms-site ranger.service.https.attrib.keystore.pass ${KEYSTOREPASS},
        ranger-kms-site ranger.service.https.attrib.ssl.enabled   true,
        ranger-kms-site ranger.service.https.port 9393,
      	ranger-kms-site ranger.truststore.file: ${TRUSTSTORELOC},
      	ranger-kms-site ranger.truststore.password: ${TRUSTSTOREPASS},
	ranger-kms-env kms_port 6182,
      	ranger-kms-policymgr-ssl ranger.service.http.enabled false,
    	ranger-kms-policymgr-ssl xasecure.policymgr.clientssl.keystore ${RANGERKEYSTORELOC},
      	ranger-kms-policymgr-ssl xasecure.policymgr.clientssl.keystore.password: ${KEYSTOREPASS},
      	ranger-kms-policymgr-ssl xasecure.policymgr.clientssl.truststore ${TRUSTSTORELOC},
      	ranger-kms-policymgr-ssl xasecure.policymgr.clientssl.truststore.password ${TRUSTSTOREPASS},
    	ranger-kms-security ranger.plugin.kms.policy.rest.url ${RANGERURL},
    	hdfs-site dfs.encryption.key.provider.uri  ${KMSURL},
    	core-site hadoop.security.key.provider.path ${KMSURL}
EOF
}

function validate() {
# Steps to validate 

        echo 
	echo "Validate:"
        echo "Test by using Ambari to restart the Ranger KMS service."
	echo "Test by using Ambari to restart the Ranger Admin service."
	echo "Test by using Ambari to restart the HDFS service."
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
setPKIPass
setServer

# Run Ranger KMS
createKeystore
exportCert
importKey
moveKey

# Run Truststore
importTruststore
moveTruststore

# Config
configAmbari
cleanupAmbari

# Validate
validate
