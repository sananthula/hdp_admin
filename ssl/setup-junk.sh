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

# Title: setup-ssl-hdfs.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script setups HDFS SSL encryption in support of
# hdfs and WebHDFS.
# Note: This script must be run on the Ambari server.
# Note: The CA install script and the setup for pki must be run first.

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
	LOGFILE=${LOGDIR}/setup-ssl-hdfs-${DATETIME}.log
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
# Set master servers.

        echo -n "IMPORTANT: Use Ambari to stop all HDFS services. "
        checkContinue
}

function configAmbari() {
# Required configurations changes for Ambari. You can check these
# at haoop.apache.org default properties.

	  echo "Set HDFS properties and values in Ambari." | tee -a ${LOGFILE}

cat << EOF | setAmbari
        core-site hadoop.ssl.require.client.cert   false,
        core-site hadoop.ssl.hostname.verifier   DEFAULT,
        hdfs-site dfs.https.enable    true,
        hdfs-site dfs.http.policy    HTTPS_ONLY,
        hdfs-site dfs.client-https.need-auth    false
EOF
}

function validateSSL() {
# Steps to validate

	echo
	echo "Validate"
	echo "1. Review the log file at ${LOGFILE}."
	echo "2. Use Ambari to restart the HDFS services."
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
setCertVar
setPKIPass
setAmbariVar
stopService

# Config Ambari
configAmbari
cleanupAmbari

# Next steps
validateSSL
