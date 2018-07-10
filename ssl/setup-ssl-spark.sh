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

# Title: setup-ssl-spark.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script setups Spark SSL encryption.
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
	LOGFILE=${LOGDIR}/setup-ssl-spark-${DATETIME}.log
}

function callSSLFunction() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/ssl/ssl-functions.sh ]; then
                source ${HOME}/sbin/ssl/ssl-functions.sh
        else
                echo "ERROR The file ssl-functions not found."
                echo "This required file provides supporting functions."
        fi
}

function stopService() {
# Stop Spark services

        echo -n "IMPORTANT: Use Ambari to stop all Spark services. "
        checkContinue
}

function configAmbari() {
# Required configurations changes for Ambari. Most of these should
# be left at the default. Change these only after careful research.

	echo "Set Ambari Infra and Metrics properties and values in Ambari." | tee -a ${LOGFILE}
	
cat <<EOF | setAmbari 
      	spark-defaults spark-defaults spark.ssl.keyStore ${KEYSTORELOC},
    	spark-defaults spark.ssl.enabled true,
      	spark-defaults spark.ssl.protocol TLS,
      	spark-defaults spark.ssl.enabledAlgorithms TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA,
      	spark-defaults spark.ssl.keyPassword ${KEYPASS},
      	spark-defaults spark.ssl.keyStorePassword ${KEYSTOREPASS},
      	spark-defaults spark.ssl.trustStore ${TRUSTSTORELOC},
      	spark-defaults spark.ssl.trustStorePassword ${TRUSTSTOREPASS},
      	spark2-defaults spark.ui.https.enabled true,
  	spark2-defaults spark.ssl.enabled true,
      	spark2-defaults spark.ssl.enabledAlgorithms TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA,
      	spark2-defaults spark.ssl.protocol TLS,
      	spark2-defaults spark.ssl.keyPassword ${KEYPASS},
      	spark2-defaults spark.ssl.keyStore ${KEYSTORELOC},
      	spark2-defaults spark.ssl.keyStorePassword ${KEYSTOREPASS},
      	spark2-defaults spark.ssl.trustStore ${TRUSTSTORELOC},
      	spark2-defaults spark.ssl.trustStorePassword ${TRUSTSTOREPASS}
EOF
}

function validateSSL() {
# Steps to validate

	echo
	echo "Validate:"
	echo "1. Review the log file at ${LOGFILE}."
	echo "2. Test by using Ambari to restart the Spark services."
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
