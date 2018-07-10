#!/bin/bash

# Hortonworks University
# This script is for training purposes only and is to be used only
# in support of approved Hortonworks University exercises. Hortonworks
# assumes no liability for use outside of our training environments.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Name: ssl-functions.sh
# Author: WKD  
# Date: 1MAR18
# Purpose: The functions and configurations required for ssl.

# VARIABLES
CADIR=/etc/pki/CA
WRKDIR=${HOME}/pki
SERVERDIR=/etc/security/serverKeys
SERVERSTORE=server.jks
SERVERSTORELOC=${SERVERDIR}/${SERVERSTORE}
CLIENTDIR=/etc/security/clientKeys
CLIENTSTORE=client.jks
CLIENTSTORELOC=${CLIENTDIR}/${CLIENTSTORE}
TRUSTSTORE=truststore.jks
SERVERTRUSTLOC=${SERVERDIR}/${TRUSTSTORE}
CLIENTTRUSTLOC=${CLIENTDIR}/${TRUSTSTORE}
RANGERCONFIG=./ranger-config.csv 
RANGERTRUSTSTORE=ranger-truststore.jks
RANGERTRUSTLOC=${SERVERDIR}/${RANGERTRUSTSTORE}

# FUNCTIONS
function headingSSL() {
        echo "**************************************************************"
        echo "*             S E T U P   S S L   F O R   H D P              * "
        echo "**************************************************************"
}

function createWrkDir() {
# Create a working directory on the Ambari server.

        if [ ! -e ${WRKDIR} ]; then
                echo "Making ${WRKDIR}" | tee -a ${LOGFILE}
                mkdir ${WRKDIR} >> ${LOGFILE} 2>&1
        fi
}

function createSecurityDir() {
# First check for /etc/security/serverKeys and /etc/security/clientKeys 
# directories. If they are not found than make them.

        for HOST in $(cat ${HOSTS}); do
                # Make the server directory
                echo "Make the ${SERVERDIR}/serverKeys directory on ${HOST}" | tee -a ${LOGFILE}
                ssh -tt ${HOST} -C "
			sudo mkdir -p ${SERVERDIR};
			sudo chgrp -R yarn:hadoop ${SERVERDIR}
			sudo chmod 755 ${SERVERDIR}
			sudo mkdir -p ${CLIENTDIR};
			sudo chgrp -R yarn:hadoop ${CLIENTDIR}
			sudo chmod 755 ${CLIENTDIR}
		" >> ${LOGFILE} 2>&1
        done
}

function setPKIPass() {
# Set the password for the stores and the keys
# The command set -a exports all variables created in this function
# The command set +a turns off the export. 

	if [ -z ${KEYPASS} ]; then
		set -a
        	while : ; do
			echo
			echo "IMPORTANT: All passwords must have at least six characters"
                	read -p "Enter password for all keys: " KEYPASS
                	read -p "Enter the password for the keystores: " KEYSTOREPASS 
                	read -p "Enter the password for the truststores: " TRUSTSTOREPASS 
                	echo "Key password: ${KEYPASS}"
                	echo "Keystore password: ${KEYSTOREPASS}"
                	echo "Truststore password: ${TRUSTSTOREPASS}"
                	checkCorrect
        	done
		set +a
	fi
}

function setCertVar() {
# Set common variables for SSL

	# Variables for certs
	COUNTRY=US
	STATE=CA
	CITY=Santa_Clara
	ORG=HWX
	UNIT=EDU
	EMAIL=wkd@hwx.net
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

			#--value=${z} &> /dev/null || echo "ERROR: Failed to set ${y} to ${z} in ${x} | tee -a ${LOGFILE}" 
function setURL() {
# Set URL required for SSL

        TIMELINEURL=$(getAmbari "yarn-site" "yarn.timeline-service.webapp.address"):8190
        HISTORYURL='https://'$(getAmbari "mapred-site" "mapreduce.jobhistory.webapp.address"):19889
        KMSURL='https://'$(getAmbari "core-site" "hadoop.security.key.provider.path"):9393
        ATLASURL=$(getAmbari "application-properties" "atlas.rest.address"):21443
	RANGERURL=$(getAmbari "admin-properties" "policymgr_external_url"):6182
}

function cleanupAmbari() {
# Remove the doSet_version file created by Ambari configs

	rm -f doSet_version*json
}
