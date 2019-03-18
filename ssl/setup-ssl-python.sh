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

# Title: setup-ssl-python.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script setups Python SSL encryption in support of
# Infra, Metrics, and LogSearch. 
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
	LOGFILE=${LOGDIR}/setup-ssl-ambari-${DATETIME}.log
}


function stopService() {
# Stop Ambari services

        echo -n "IMPORTANT: Use Ambari to stop the Infra, Metrics, and Logsearch services. "
        checkContinue
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

function configAmbari() {
# Required configurations changes for Ambari. Most of these should
# be left at the default. Change these only after careful research.

	echo "Set Ambari Infra and Metrics properties and values in Ambari." | tee -a ${LOGFILE}
	
cat <<EOF | setAmbari 
      	ams-ssl-server ssl.server.keystore.location ${KEYSTORELOC},
      	ams-ssl-server ssl.server.keystore.password ${KEYSTOREPASS},
      	ams-ssl-server ssl.server.keystore.type jks,
    	ams-ssl-server ssl.server.truststore.location ${TRUSTSTORELOC},
      	ams-ssl-server ssl.server.truststore.password ${TRUSTSTOREPASS},
      	ams-ssl-server ssl.server.truststore.type jks,
    	ams-ssl-client ssl.client.truststore.location ${TRUSTSTORELOC},
      	ams-ssl-client ssl.client.truststore.password ${TRUSTSTOREPASS},
      	ams-ssl-client ssl.client.truststore.type jks,
    	infra-solr-env infra_solr_ssl_enabled true,
      	infra-solr-env infra_solr_keystore_location ${KEYSTORELOC},
      	infra-solr-env infra_solr_keystore_password ${KEYSTOREPASS},
      	infra-solr-env infra_solr_keystore_type jks,
       	infra-solr-env infra_solr_truststore_location ${TRUSTSTORELOC},
      	infra-solr-env infra_solr_truststore_password ${TRUSTSTOREPASS},
      	infra-solr-env infra_solr_truststore_type jks,
 	logsearch-env logsearch_ui_protocol https,
      	logsearch-env logsearch_truststore_location ${TRUSTSTORELOC},
      	logsearch-env logsearch_truststore_password ${TRUSTSTOREPASS},
      	logsearch-env logsearch_truststore_type jks,
      	logsearch-env logsearch_keystore_location ${KEYSTORELOC},
      	logsearch-env logsearch_keystore_password ${KEYSTOREPASS},
      	logsearch-env logsearch_keystore_type jks,
    	logfeeder-env logfeeder_truststore_location ${TRUSTSTORELOC},
      	logfeeder-env logfeeder_truststore_password ${TRUSTSTOREPASS},
      	logfeeder-env logfeeder_truststore_type jks,
      	logfeeder-env logfeeder_keystore_location ${KEYSTORELOC},
      	logfeeder-env logfeeder_keystore_password ${KEYSTOREPASS},
      	logfeeder-env logfeeder_keystore_type jks
EOF
}

function validateSSL() {
# Steps to validate

	echo
	echo "Validate:"
	echo "1. Review the log file at ${LOGFILE}."
	echo "2. Test by using Ambari to restart the Ambari Infra and Metric services."
	echo "3. Test by using Ambari to restart the Log Search services."
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
