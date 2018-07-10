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

# Name: build-ssh-keypairs.sh
# Author: WKD 
# Date: 1MAR18 
# Purpose: This creates the ssh keys to be used by Ambari for the Edu 
# cluster. These keys will have to be put into place manually.
# Do not confuse these keys used by AWS for the centos users.

# CHANGES
# RFC-1274 Script Maintenance

# VARIABLES
CERTDIR=/Users/hdpedu/certs/ref

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

function createSSHKey() {
# Create a ssh private and public key, retain a copy in the certs directory.

	if [ -d ${CERTDIR} ]; then
		echo -n "The ${CERTDIR} directory exists. Remove it?"
		checkContinue
                rm -r ${CERTDIR}
		mkdir -p ${CERTDIR}
	else
		mkdir -p ${CERTDIR}
	fi

	# Create keys
	ssh-keygen -f ${CERTDIR}/reference-keypair.pem

	# Build keys
	cp ${CERTDIR}/reference-keypair.pem ${CERTDIR}/id_rsa 
	cp ${CERTDIR}/reference.pem.pub ${CERTDIR}/authorized_keys

	# Set permissions	
	chmod 400 ${CERTDIR}/reference-keypair.pem
	chmod 400 ${CERTDIR}/id_rsa
	chmod 600 ${CERTDIR}/authorized_keys
}

# MAIN
# Source functions
callFunction

# Run build
createSSHKey
