#!/bin/sh

# Hortonworks University
# This script is for training purposes only and is to be used only 
# in support of approved Hortonworks University exercises. Hortonworks
# assumes no liability for use outside of our traning environments.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Name: create-ambari-keys.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Script to install ssl certificate, both public and private
# key, into /etc/pki/tls on the Ambari server.

# VARIABLES
KEYOWNER=ambari
AMBARI_SERVER=$(curl icanhazptr.com)

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0)"
        exit 1
}

function callFunction() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/functions.sh ]; then
                source ${HOME}/sbin/functions.sh
        else
                echo "ERROR: The file ${HOME}/sbin/functions not found."
                echo "This required file provides supporting functions."
        fi
}

function createKey() {
# Use openssl to generate a key and a crt file

	sudo openssl req -x509 -newkey rsa:4096 -keyout ${KEYOWNER}.key -out ${KEYOWNER}.crt -days 365 -nodes -subj "/CN=${AMBARI_SERVER}"
}

function mvKey() {
# Move the key and the crt into /etc/pki/tls

	sudo chown ${KEYOWNER} ${KEYOWNER}.crt ${KEYOWNER}.key   
	sudo chmod 0400 ${KEYOWNER}.crt ${KEYOWNER}.key   
	sudo mv ${KEYOWNER}.crt /etc/pki/tls/certs/   
	sudo mv ${KEYOWNER}.key /etc/pki/tls/private/
}

function listKey() {
# List the keys

	ls /etc/pki/tls/certs /etc/pki/tls/private
}

# MAIN
# Source functions
callFunction

# Run checks
checkSudo

# Create keys
cd /tmp
createKey
mvKey
listKey
