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

# Title: setup-ssl-nifi.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script setups NiFi SSL encryption 
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
	LOGFILE=${LOGDIR}/setup-ssl-nifi-${DATETIME}.log
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

	echo "Set NiFi properties and values in Ambari." | tee -a ${LOGFILE}
	
cat <<EOF | setAmbari 
    	nifi-ambari-ssl-config nifi.node.ssl.isenabled true,
       	nifi-ambari-ssl-config nifi.security.needClientAuth true,
       	nifi-ambari-ssl-config nifi.security.keyPasswd ${KEYPASS},
       	nifi-ambari-ssl-config nifi.security.keystore ${KEYSTORELOC},
       	nifi-ambari-ssl-config nifi.security.keystorePasswd ${KEYSTOREPASS},
       	nifi-ambari-ssl-config nifi.security.keystoreType jks,
       	nifi-ambari-ssl-config nifi.security.truststore ${TRUSTSTORELOC},
       	nifi-ambari-ssl-config nifi.security.truststorePasswd ${TRUSTSTOREPASS},
       	nifi-ambari-ssl-config nifi.security.truststoreType jks,
      	nifi-registry-ambari-ssl-config nifi.security.keyPasswd ${KEYPASS},
      	nifi-registry-ambari-ssl-config nifi.security.keystorePasswd ${KEYSTOREPASS},
      	nifi-registry-ambari-ssl-config nifi.security.truststorePasswd ${TRUSTSTOREPASS},
      	nifi-registry-ambari-ssl-config nifi.registry.ssl.isenabled true,
      	nifi-registry-ambari-ssl-config nifi.registry.security.needClientAuth false,
    	nifi-registry-ambari-ssl-config nifi.registry.security.keystore ${KEYSTORELOC},
      	nifi-registry-ambari-ssl-config nifi.registry.security.keystoreType jks,
      	nifi-registry-ambari-ssl-config nifi.registry.security.truststore ${TRUSTSTORELOC},
      	nifi-registry-ambari-ssl-config nifi.registry.security.truststoreType jks,
      	nifi-registry-ambari-ssl-config nifi.toolkit.tls.regenerate false,
    	nifi-properties nifi.security.identity.mapping.pattern.dn ^[Cc][Nn]=(.*?),(.*?)$,
       	nifi-properties nifi.security.identity.mapping.value.dn $1,
    	ranger-nifi-plugin-properties common.name.for.certificate ${RANGERCOMMONNAME},
    	ranger-nifi-policymgr-ssl xasecure.policymgr.clientssl.keystore ${RANGERKEYSTORELOC},
      	ranger-nifi-policymgr-ssl xasecure.policymgr.clientssl.keystore.password ${KEYSTOREPASS},
      	ranger-nifi-policymgr-ssl xasecure.policymgr.clientssl.truststore ${TRUSTSTORELOC},
      	ranger-nifi-policymgr-ssl xasecure.policymgr.clientssl.truststore.password ${TRUSTSTOREPASS},
    	ranger-nifi-security ranger.plugin.nifi.policy.rest.url ${RANGERURL}
EOF
}

function validateSSL() {
# Steps to validate

	echo
	echo "Validate:"
	echo "1. Review the log file at ${LOGFILE}."
	echo "2. Test by using Ambari to restart the NiFi services."
	echo 
}

# MAIN
# Source functions
callFunction

# Run checks 
checkSudo
checkArg 0
checkAmbari
showIntro

# Run setups
setupLog ${LOGFILE}
setPKIPass

# Config Ambari
configAmbari
cleanupAmbari

# Next steps
validateSSL
