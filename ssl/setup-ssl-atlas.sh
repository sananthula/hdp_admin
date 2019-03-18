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

# Title: setup-ssl-atlas.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script setups Hive SSL encryption in support of
# hiveserver2 and beeline. 
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
	LOGFILE=${LOGDIR}/setup-ssl-atlas-${DATETIME}.log
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
# Stop Atlas services

        echo -n "IMPORTANT: Use Ambari to stop all Atlas services. "
        checkContinue
}

function configAmbari() {
# Required configurations changes for Ambari. Most of these should
# be left at the default. Change these only after careful research.

	echo "Set Atlas properties and values in Ambari." | tee -a ${LOGFILE}
	
cat <<EOF | setAmbari 
      	application-proprties atlas.enableTLS true,
      	application-proprties keystore.file ${KEYSTORELOC},
 	application-proprties truststore.file ${TRUSTSTORELOC},
      	application-proprties cert.stores.credential.provider.path jceks://file//etc/pki/creds.jceks,
      	application-proprties atlas.rest.address ${ATLASURL},
    	atlas-env metadata_opts -Dlog4j.configuration=atlas-log4j.xml -Djavax.net.ssl.trustStore=${TRUSTSTORELOC} -Djavax.net.ssl.trustStorePassword=\${TRUSTSTOREPASS}\,
    	ranger-atlas-security ranger.plugin.atlas.policy.rest.url ${RANGERURL},
    	ranger-atlas-policymgr-ssl xasecure.policymgr.clientssl.keystore ${RANGERKEYSTORELOC},
      	ranger-atlas-policymgr-ssl xasecure.policymgr.clientssl.keystore.password ${KEYSTOREPASS},
      	ranger-atlas-policymgr-ssl xasecure.policymgr.clientssl.truststore ${TRUSTSTORELOC},
      	ranger-atlas-policymgr-ssl xasecure.policymgr.clientssl.truststore.password ${TRUSTSTOREPASS},
    	ranger-atlas-plugin-properties common.name.for.certificate ${RANGERCOMMONNAME}
EOF
}

function validateSSL() {
# Steps to validate

	echo
	echo "Validate:"
	echo "1. Review the log file at ${LOGFILE}."
	echo "2. Test by using Ambari to restart the Atlas services."
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
