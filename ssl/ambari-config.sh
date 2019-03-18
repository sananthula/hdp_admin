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

# Title: ambari-config.sh
# Author: WKD
# Date: 27JUL18
# Purpose: This is a script for running various Ambari configurations 

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
                source ${HOME}/functions.sh
        else
                echo "ERROR: The file ${HOME}/functions not found."
                echo "This required file provides supporting functions."
	fi
}

function checkAmbari() {
# All of the SSL setup scripts must be run from the Ambari server.

        if [ ! -e "/var/lib/ambari-server/resources/scripts/configs.py" ]; then
                echo "ERROR: All SSL scripts must be run from the Ambari server."
                usage
        fi
}

function setAmbariVar() {
# Set variables for Ambari. These are used when running setAmbari.
# The command set -a exports all variables created in this function.
# The command set +a turns off the export.

        if [ -z ${AMBARIADMIN} ]; then
                set -a
                while : ; do
                        echo
                        read -p "Enter name of the Ambari admin: " AMBARIADMIN
                        read -p "Enter password for the Ambari admin: " AMBARIPASS
                        read -p "Enter the FQDN for the Ambari server: " AMBARISERVER
                        read -p "Enter the cluster name: " CLUSTER
                        read -p "Enter protocol (http|https): " OPTION
                                case ${OPTION} in
                                        http|HTTP)
                                                PROTOCOL=http
                                                PORT=8080
                                                ;;
                                        https|HTTPS)
                                                PROTOCOL=https
                                                PORT=8443
                                                ;;
                                        *)
                                                echo "ERROR: Protocol must be set to http or https."
                                                ;;
                                esac
                        echo "Ambari admin: ${AMBARIADMIN}"
                        echo "Ambari password: ${AMBARIPASS}"
                        echo "Ambari server: ${AMBARISERVER}"
                        echo "Cluster name: ${CLUSTER}"
                        echo "Protocol: ${PROTOCOL}"
                        checkCorrect
                done
                set +a
        fi
}

function getAmbari() {
# This function sets configurations in the Ambari CMDB.

        TYPE=$1
        PROP=$2

        /var/lib/ambari-server/resources/scripts/configs.py \
                --user=${AMBARIADMIN} \
                --password=${AMBARIPASS} \
                --host=${AMBARISERVER} \
                --protocol=${PROTOCOL} \
                --port=${PORT} \
                --cluster=${CLUSTER} \
                --action=get \
                --config-type=${TYPE} \
                --key=${PROP}
}

function setAmbari() {
# This function sets configurations in the Ambari CMDB.

        while read x y z; do
                z=${z/,}
                z=${z//\"}
                if [ -z "$z" ]; then continue; fi
                echo "Setting ${y} to ${z} in ${x} " | tee -a ${LOGFILE}

                sudo /var/lib/ambari-server/resources/scripts/configs.py \
                        --user=${AMBARIADMIN} \
                        --password=${AMBARIPASS} \
                        --host=${AMBARISERVER} \
                        --protocol=${PROTOCOL} \
                        --port=${PORT} \
                        --cluster=${CLUSTER} \
                        --action=set \
                        --config-type=$x \
                        --key=$y \
                        --value=${z} &> /dev/null || echo "ERROR: Failed to set ${y} to ${z} in ${x} | tee -a ${LOGFILE}"
        done
}

function cleanupAmbari() {
# Remove the doSet_version file created by Ambari configs

        rm -f doSet_version*json
}

function configAddRemoteCluster() {
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

function headingAmbari() {
        echo "**************************************************************"
        echo "*             C O N F I G U R E   A M B A R I                * "
        echo "**************************************************************"
}

function showIntro() {
# Intro screen
	clear
	headingAmbari
	echo "
 Purpose: This is a configuration tool for Ambari. It uses the Ambari REST API to
pass configuration changes to the Ambari CMDB.
"
	checkContinue
}

function showMenu() {
	clear
	headingAmbari

	echo "  
 1. Configure HA for distcp 
"
	read -p "Enter your selection (q to quit): " OPTION junk
	
	# If there is an empty OPTION (Pressing ENTER) redisplays
	[ "${OPTION}" = "" ] && continue
}

function runOption() {
 	case $OPTION in
		1) setAmbariVar
		   configAddRemoteCluster
		   cleanupAmbari
		   ;;
		q*|Q*) clear; 
	   	   quit 0
		   ;;
		*) echo "Incorrect entry, please try again"
		   ;;
        esac
}

function runMenu() {

	while true; do
		showMenu
		clear
		runOption
		pause
	done
}

# MAIN
# Source functions
callFunction

# Run checks
checkSudo
checkArg 0
checkAmbari

# Intro 
clear
headingAmbari
setIntro

# Run menu
runMenu
