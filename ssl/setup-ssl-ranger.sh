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

# Title: setup-ranger-server.sh
# Author: Vladimir Zlatkin and WKD
# Date: 1MAR18 
# Purpose: This script setups Ranger SSL encryption.
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
	LOGFILE=${LOGDIR}/setup-ranger-server-${DATETIME}.log
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
# Stop Ranger services

        echo -n "IMPORTANT: Use Ambari to stop all Ranger services. "
        checkContinue
}

function configAmbari() {
# Configure the Ambari server for Ranger

	echo "Set Ranger Server properties and values in Ambari." | tee -a ${LOGFILE} 

        #ranger-admin-site ranger.service.https.attrib.client.auth "false",
        #ranger-admin-site ranger.service.https.attrib.clientAuth   "want",
cat <<EOF | setAmbari
	admin-properties policymgr_external_url ${RANGERURL},
      	ranger-admin-site ranger.service.http.enabled false,
      	ranger-admin-site ranger.service.https.attrib.ssl.enabled true,
    	ranger-admin-site ranger.https.attrib.keystore.file ${KEYSTORELOC},
      	ranger-admin-site ranger.service.https.attrib.keystore.file ${KEYSTORELOC},
      	ranger-admin-site ranger.service.https.attrib.keystore.keyalias gateway-identity,
      	ranger-admin-site ranger.service.https.attrib.keystore.pass ${KEYSTOREPASS},
      	ranger-admin-site ranger.service.https.port 6182,
      	ranger-admin-site ranger.truststore.file ${TRUSTSTORELOC},
      	ranger-admin-site ranger.truststore.password ${TRUSTSTOREPASS},
    	ranger-tagsync-policymgr-ssl xasecure.policymgr.clientssl.keystore ${RANGERKEYSTORELOC},
      	ranger-tagsync-policymgr-ssl xasecure.policymgr.clientssl.keystore.password ${KEYSTOREPASS},
      	ranger-tagsync-policymgr-ssl xasecure.policymgr.clientssl.truststore ${TRUSTSTORELOC},
      	ranger-tagsync-policymgr-ssl xasecure.policymgr.clientssl.truststore.password ${TRUSTSTOREPASS},
    	ranger-ugsync-site xasecure.policymgr.clientssl.keystore ${RANGERKEYSTORELOC},
      	ranger-tagsync-policymgr-ssl xasecure.policymgr.clientssl.keystore.password ${KEYPASS},
      	ranger-tagsync-policymgr-ssl xasecure.policymgr.clientssl.truststore ${TRUSTSTORELOC},
      	ranger-tagsync-policymgr-ssl xasecure.policymgr.clientssl.truststore.password ${TRUSTSTOREPASS},
      	ranger-tagsync-policymgr-ssl ranger.usersync.truststore.file ${TRUSTSTORELOC},
      	ranger-tagsync-policymgr-ssl ranger.usersync.truststore.password ${TRUSTSTOREPASS},
    	atlas-tagsync-ssl xasecure.policymgr.clientssl.keystore ${RANGERKEYSTORELOC},
      	atlas-tagsync-ssl xasecure.policymgr.clientssl.keystore.password ${KEYSTOREPASS},
      	atlas-tagsync-ssl xasecure.policymgr.clientssl.truststore ${TRUSTSTORELOC},
      	atlas-tagsync-ssl xasecure.policymgr.clientssl.truststore.password ${TRUSTSTOREPASS}
EOF
}

function validateSSL() {
# Steps to validate 

        echo 
	echo "Validate:"
        echo "Test by using Ambari to restart the Ranger service."
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
setAmbariVar

# Config
configAmbari
cleanupAmbari

# Validate
validateSSL
