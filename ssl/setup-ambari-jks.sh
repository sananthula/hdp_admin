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

# Title: setup-ambari-jks.sh
# Author: WKD and Validmir Zlatkin
# Date: 1MAR18
# Purpose: This script setups Ambari truststore. Enabling the Ambari
# truststore allows Ambari views to use SSL, for example this
# is required to reach the YARN Queue Manager view when HTTPS
# is turned on.
# This setup uses the Hadoop truststore. It is important to
# ensure you line up on the right .crt and .key file when configuring
# the Ambari crt and key. This should be the hostname located in
# the working directory. This script configures on the all.jks 
# created by the Hadoop Keystores.
# Note: This script must be run on the Ambari server.
# Note: This is a one time deal. After running this once the 
# ambari-server setup-security command adds an extra line in the setup.
# After excuting this script once you will have to manually run 
# ambari-server setup command.

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
	LOGFILE=${LOGDIR}/setup-ambari-jks-${DATETIME}.log
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
    	sudo rpm -q expect || sudo yum -y install expect >> ${LOGFILE} 2>&1
}

function createExpect() {
# Create the expect script for Ambari configuration of the truststore.
# Choose option 4 in order to configure a new truststore for use by 
# the Ambari server. The file /var/lib/ambari-server/keys/cacerts.jks
# will not be created until the import is completed.

echo "Create the expect script for setting the Ambari truststore" | tee -a ${LOGFILE}
    	cat <<EOF > ${WRKDIR}/ambari-server-jks.exp
#!/usr/bin/expect
spawn "/usr/sbin/ambari-server" "setup-security"
expect "Enter choice"
send "4\r"
expect "Do you want to configure a truststore"
send "y\r"
expect "The truststore is already configured"
send "y\r"
expect "TrustStore type"
send "jks\r"
expect "Path to TrustStore file"
send "${SECDIR}/${TRUSTSTORE}\r"
expect "Password for TrustStore"
send "${KEYSTOREPASS}\r"
expect "Re-enter password"
send "${KEYSTOREPASS}\r"
interact
EOF

	checkFile ${WRKDIR}/ambari-server-jks.exp
}

function runExpect() { 
# Run the Ambari truststore expect script

    	if grep -q 'api.ssl=true' /etc/ambari-server/conf/ambari.properties; then
		echo "Run the expect script to configure the Ambari truststore" | tee -a ${LOGFILE}
        	sudo /usr/bin/expect ${WRKDIR}/ambari-server-jks.exp >> ${LOGFILE} 2>&1
	else
		echo "ERROR: The expect script failed to run. Execute the HTTPS script first." | tee -a ${LOGFILE}
		exit 1
    	fi
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
 	echo "Ambari Server started for the Ambari truststore" | tee -a ${LOGFILE}
}

function cleanExpect() {
# Remove the expect scripts

	if [ -f ${WRKDIR}/ambari-server-jks.exp ]; then
    		rm -f  ${WRKDIR}/ambari-server-jks.exp >> ${LOGFILE} 2>&1
	fi
}

function validate() {
# Validation

	echo
	echo "1. Review the log file at ${LOGFILE}."
	echo "2. Verify that the Ambari truststore file was created with right perms."
	echo "    sudo ls -l /var/lib/ambari-server/keys"
	echo "3. Check the contents of the truststore file."
	echo "    sudo keystool -list -v -keystore ${AMBARI_STORE_DIR}/${AMBARI_STORE_NAME}.jks"
	echo "4. Validate the Ambari truststore with"
	echo "    Ambari Views > YARN Queue Manager"
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

# Run install
installExpect

# Run functions 
createExpect
runExpect
restartAmbari

# Validate
validate

# Optional cleanup
#cleanExpect
