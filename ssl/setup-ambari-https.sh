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

# Title: setup-ambari-https.sh
# Author: WKD and Validmir Zlatkin
# Date: 1MAR18
# Purpose: This script setups Ambari SSL encryption. Enabling SSL 
# encryption then requires users to access Ambari through HTTPS at 
# port 8443. Enabling the Ambari truststore allows Ambari views to 
# use SSL, for example this is required to reach the YARN Queue Manager 
# view when HTTPS is turned on.
# Note: There is an issue of running both Ambari HTTPS and 
# truststore in the AWS environment. To resolve we use the 
# AWS internal IP address for the CN. This is out of specs
# and results in warning entries in the Ambari server logs.
# Note: This script must be run on the Ambari server.

# VARIABLE
NUMARGS=$#
SSLDIR=/etc/pki/tls
HOST=$(hostname -f)
AMBARI_CRT=ambari-server.crt
AMBARI_KEY=ambari-server.key

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

	LOGFILE=${LOGDIR}/setup-ambari-https-${DATETIME}.log
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

function installExpect() {
# Install the expect software package

	echo "Install the expect software package" | tee -a ${LOGFILE}
    	sudo rpm -q expect || sudo yum install -y expect >> ${LOGFILE} 2>&1
}

function copyKey() {
# Move the key into /etc/pki/tls/private. Set the ownership and the permissions.

	if [ ! -e ${WRKDIR}/${HOST}.crt ]; then
		echo "Copying the Ambari private key to ${SSLDIR}" | tee -a ${LOGFILE}
        	sudo cp ${WRKDIR}/${HOST}.key ${SSLDIR}/${AMBARI_KEY} >> ${LOGFILE} 2>&1
        	sudo chown root:root ${SSLDIR}/${AMBARI_KEY} >> ${LOGFILE} 2>&1
        	sudo chmod 0400 ${SSLDIR}/${AMBARI_KEY} >> ${LOGFILE} 2>&1
	fi
}

function copyCert() {
# Move the crt into /etc/pki/tls/certs. Set the ownership and the permissions.

	if [ ! -e ${WRKDIR}/${HOST}.crt ]; then
		echo "Copying the Ambari certificate to ${SSLDIR}" | tee -a ${LOGFILE}
        	sudo cp ${WRKDIR}/${HOST}.crt ${SSLDIR}/${AMBARI_CRT} >> ${LOGFILE} 2>&1
        	sudo chown root:root ${SSLDIR}/${AMBARI_CRT}  >> ${LOGFILE} 2>&1
        	sudo chmod 0444 ${SSLDIR}/${AMBARI_CRT} >> ${LOGFILE} 2>&1
	fi
}

function createExpect() {
# Create the expect script for Ambari HTTPS

	echo "Create the expect script for Ambari HTTPS" | tee -a ${LOGFILE}
	cat <<EOF > ${WRKDIR}/ambari-server-https.exp
#!/usr/bin/expect
spawn "/usr/sbin/ambari-server" "setup-security"
expect "Enter choice"
send "1\r"
expect "Do you want to configure HTTPS"
send "y\r"
expect "SSL port"
send "8443\r"
expect "Enter path to Certificate"
send "${SSLDIR}/${AMBARI_CRT}\r"
expect "Enter path to Private Key"
send "${AMBARI_KEY_DIR}/${AMBARI_KEY}\r"
expect "Please enter password for Private Key"
send "${KEYPASS}\r"
send "${KEYPASS}\r"
interact
EOF

	checkFile ${WRKDIR}/ambari-server-https.exp
}

function runExpect() { 
# Run the Ambari HTTPS expect script

	echo "Run the expect script for Ambari HTTPS" | tee -a ${LOGFILE}
       	sudo /usr/bin/expect ${WRKDIR}/ambari-server-https.exp >> ${LOGFILE} 2>&1
	sleep 3
	echo
}

function restartAmbari() {
# Restart the Ambari server and then clean up.

	echo "Restarting Ambari Server for HTTPS" | tee -a ${LOGFILE}
        sudo ambari-server restart >> ${LOGFILE} 2>&1

        while true; do
                if tail -100 /var/log/ambari-server/ambari-server.log | grep -q 'Started Services'; then
                        break
                else
                        echo -n .
                        sleep 3
                fi
        done
	echo "Ambari Server started for HTTPS" | tee -a ${LOGFILE}
}

function validate() {
# Steps to validate

	echo
	echo "Validate:"
	echo "1. Review the log file at ${LOGFILE}."
	echo "2. Login to the Ambari Web UI with https://${AMBARISERVER}:8443"
	echo "3. Test HTTPS from the an external terminal."
	echo "    wget -O- --no-check-certificate 'https://${AMBARISERVER}:8443/#/main/dashboard/metrics' "
	echo
}

function cleanExpect() {
# Remove the expect scripts
	if [ -f ${WRKDIR}/ambari-server-https.exp ]; then
    		rm -f ${WRKDIR}/ambari-server-https.exp >> ${LOGFILE} 2>&1
	fi
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

# Run install
installExpect

# Run functions 
createExpect
runExpect
restartAmbari

# Validate
validate

# Optional clean up
#cleanExpect
