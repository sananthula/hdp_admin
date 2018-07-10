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

# Title: pushkrb5.sh
# Author: WKD
# Date: 150827
# Purpose: Push Kerberos configuration file to cluster.

# VARIABLES
NUMARGS=$#
ETCDIR=${HOME}/etc
HOSTS=${HOME}/etc/listhosts.txt

# FUNCTIONS
function usage() {
    	echo "Usage: sudo $(basename $0)" 
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

function pushKrb5Conf() {
# Push the Kerberos config file to all nodes

	for HOST in $(cat ${HOSTS}); do
        	echo "Copy Kerberos configs to ${HOST}" 
        	scp ${ETCDIR}/krb5.conf ${HOST}:${HOME}/krb5.conf 
		ssh -tt ${HOST} -C "sudo mv ${HOME}/krb5.conf /etc/krb5.conf"
    	done
}

# MAIN
# Source functions
callFunction

# Run checks
checkSudo
checkArg 0

# Push file
pushKrb5Conf
