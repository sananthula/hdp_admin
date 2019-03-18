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
        core-site hadoop.ssl.keystores.factory.class    org.apache.hadoop.security.ssl.FileBasedKeyStoresFactory,
        core-site hadoop.ssl.server.conf    ssl-server.xml,
        core-site hadoop.ssl.client.conf   ssl-client.xml,
        hdfs-site dfs.https.enable    true,
        hdfs-site dfs.http.policy    HTTPS_ONLY,
        hdfs-site dfs.client-https.need-auth    false,
        hdfs-site dfs.datanode.https.address    0.0.0.0:50475,
        hdfs-site dfs.namenode.https-address    0.0.0.0:50470,
        ssl-server ssl.server.keystore.location    ${SERVERSTORELOC},
        ssl-server ssl.server.keystore.password    ${KEYSTOREPASS},
        ssl-server ssl.server.keystore.keypassword    ${KEYPASS},
        ssl-server ssl.server.keystore.type    jks,
        ssl-server ssl.server.truststore.location    ${SERVERTRUSTLOC},
        ssl-server ssl.server.truststore.password    ${TRUSTSTOREPASS},
        ssl-server ssl.server.truststore.type    jks,
        ssl-client ssl.client.keystore.location   ${CLIENTSTORELOC},
        ssl-client ssl.client.keystore.password    ${KEYSTOREPASS},
        ssl-server ssl.client.keystore.keypassword    ${KEYPASS},
        ssl-client ssl.client.keystore.type    jks,
        ssl-client ssl.client.truststore.location   ${CLIENTTRUSTLOC},
        ssl-client ssl.client.truststore.password    ${TRUSTSTOREPASS},
        ssl-client ssl.client.truststore.type    jks,
	ranger-hdfs-policymgr-ssl xasecure.policymgr.clientssl.keystore ${RANGERKEYSTORELOC},
      	ranger-hdfs-policymgr-ssl xasecure.policymgr.clientssl.keystore.password ${KEYSTOREPASS},
      	ranger-hdfs-policymgr-ssl xasecure.policymgr.clientssl.truststore ${RANGERTRUSTLOC},
      	ranger-hdfs-policymgr-ssl xasecure.policymgr.clientssl.truststore.password ${TRUSTSTOREPASS},
    	ranger-hdfs-security ranger.plugin.hdfs.policy.rest.url ${RANGERURL},
    	ranger-hdfs-plugin-properties common.name.for.certificate ${RANGERCOMMONNAME}
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
