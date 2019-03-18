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

# Title: setup-ssl-yarn.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script setups YARN SSL encryption in support of
# YARN, MapReduce Shuffle, and Tez.
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
# Run functions

        if [ -f ${HOME}/sbin/functions.sh ]; then
                source ${HOME}/sbin/functions.sh
        else
                echo "ERROR: The file ${HOME}/sbin/functions not found."
                echo "This required file provides supporting functions."
	fi
	LOGFILE=${LOGDIR}/setup-ssl-yarn-${DATETIME}.log
}

function callSSLFunction() {
# SSL run functions

        if [ -f ${HOME}/sbin/ssl/ssl-functions.sh ]; then
                source ${HOME}/sbin/ssl/ssl-functions.sh
        else
                echo "ERROR: The file ssl-functions not found."
                echo "This required file provides supporting functions."
        fi
}

function stopService() {
# Stop YARN services

        echo -n "IMPORTANT: Use Ambari to stop all YARN services. "
        checkContinue
}

function setServer() {
# Set master servers.

        while : ; do
                read -p  "Enter the FQDN for the Resource Manager: " RESOURCEMANAGER 
                read -p "Enter the FQDN for the History Server: " HISTORYSERVER 
                read -p "Enter the FQDN for the Tez Server: " TEZSERVER 
                echo "Resource Manager name: ${RESOURCEMANAGER}"
                echo "History Server name: ${HISTORYSERVER}"
                echo "Tez Server name: ${TEZSERVER}"
                checkCorrect
        done
}

function configAmbari() {
# Required configurations changes for Ambari. You can check these
# at haoop.apache.org default properties.

	  echo "Set YARN properties and values in Ambari." | tee -a ${LOGFILE}

cat << EOF | setAmbari
        yarn-site yarn.http.policy    HTTPS_ONLY,
        yarn-site yarn.resourcemanager.webapp.https.address    ${RESOURCEMANAGER}:8090,
        yarn-site yarn.log.server.url    https://${HISTORYSERVER}:19443/jobhistory/logs,
        yarn-site yarn.timeline-server.webapp.https.address    https://${TIMELINESERVER}:19443/jobhistory/logs,
        yarn-site yarn.nodemanager.webapp.https.address    0.0.0.0:45443,
        mapred-site mapreduce.jobhistory.http.policy    HTTPS_ONLY,
        mapred-site mapreduce.jobhistory.webapp.https.address   ${HISTORYSERVER}:19443,
        mapred-site mapreduce.jobhistory.webapp.address    ${HISTORYSERVER}:19443,
        tez-site tez.tez-ui-history-url.base   https://${TEZSERVER}:8443/#/main/view/TEZ/tez_cluster_instance,
  	ranger-yarn-policymgr-ssl xasecure.policymgr.clientssl.keystore ${RANGERKEYSTORELOC},
      	ranger-yarn-policymgr-ssl xasecure.policymgr.clientssl.keystore.password ${KEYSTOREPASS},
       	ranger-yarn-policymgr-ssl xasecure.policymgr.clientssl.truststore ${TRUSTSTORELOC},
      	ranger-yarn-policymgr-ssl xasecure.policymgr.clientssl.truststore.password ${TRUSTSTOREPASS},
    	ranger-yarn-security ranger.plugin.yarn.policy.rest.url ${RANGERURL},
    	ranger-yarn-plugin-properties common.name.for.certificate ${RANGERCOMMONNAME}
EOF
}

function validateSSL() {
# Steps to validate

	echo
	echo "Validate"
	echo "1. Review the log file at ${LOGFILE}."
	echo "2. Test by using Ambari to restart the YARN services."
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
setServer

# Config Ambari
configAmbari
cleanupAmbari

# Next steps
validateSSL
