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

# Title: setup-ssl-hbase.sh
# Author: Valdimir Zlatkin and WKD
# Date: 1MAR18
# Purpose: This script setups HBase SSL encryption.
# Note: This script must be run on the Ambari server.
# Note: The setup for Hadoop SSL must be run first.
# IMPORTANT: In HBase, there is do direct option to add/configure the
# keystore files (JKS), it uses the JKS files configured for Hadoop. 
# The Hadoop keystores must be deployed before configuring HBase SSL.
# Note: If you are planning to have different JKS files for HDFS and HBASE 
# then you will copy the the ssl-server.xml to /etc/hbase/conf path and 
# configure for the JKS file. You will need to then uncomment and edit
# the functions for creating a certificate. 

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
	LOGFILE=${LOGDIR}/setup-ssl-hbase-${DATETIME}.log
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
# Stop HBase services 

        echo -n "IMPORTANT: Use Ambari to stop all HBase services. "
        checkContinue
}

function configAmbari() {
# Required configurations changes for Ambari. Most of these should
# be left at the default. Change these only after careful research.

	echo "Set HBase properties and values in Ambari" | tee -a ${LOGFILE}

cat <<EOF | setAmbari
        hbase-site hbase.ssl.enabled   true,
        hbase-site hbase.http.policy   HTTPS_ONLY,
        hbase-site hadoop.ssl.enabled   true,
  	ranger-hbase-policymgr-ssl xasecure.policymgr.clientssl.keystore ${RANGERKEYSTORELOC},
      	ranger-hbase-policymgr-ssl xasecure.policymgr.clientssl.keystore.password ${KEYSTOREPASS},
      	ranger-hbase-policymgr-ssl xasecure.policymgr.clientssl.truststore ${TRUSTSTORELOC},
      	ranger-hbase-policymgr-ssl xasecure.policymgr.clientssl.truststore.password: ${TRUSTSTOREPASS},
    	ranger-hbase-security ranger.plugin.hbase.policy.rest.url ${RANGERURL},
    	ranger-hbase-plugin-properties common.name.for.certificate ${RANGERCOMMONNAME}
EOF
}

function validateSSL() {
# Steps to validate 

        echo 
	echo "Validate"
	echo "1. Review the logfile at ${LOGFILE}."
        echo "2. Test by using Ambari to restart the HBase service."
        echo "3. Test connecting to the HBase Web UI from a remote terminal."
	echo " 	  https://<HOSTNAME>:16010/"
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
stopService

# Run setups
setupLog ${LOGFILE}
setPKIPass

# Config Ambari
configAmbari
cleanupAmbari

# Next steps
validateSSL
