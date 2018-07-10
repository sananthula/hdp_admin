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

# Name: create-principal.sh
# Author: WKD
# Date:  1MAR18
# Purpose: Used to create the principals for Kerberos. This only creates
# a single principale in a single location. For example for 
# oozie or for hive.
# CAUTION: This can be tricky if you are creating principals for 
# hyphenated users such as hive-webhcat. 
# IMPORTANT: The keytab must be placed into the correct conf directory. 
# In HDP this will be /etc/security/keytabs.

# VARIABLES
NUMARGS=$#
HOSTS=${HOME}/etc/listhosts.txt
PRINC=$1
REALM=$2
PASSWORD=$3

# FUNCTIONS
function usage() {
	echo "Usage: $(basename $0) [principal] [REALM] [kdc-password]"
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

function createPrinc() {
# Create a principal for each host in the cluster.

	for HOST in $(cat $HOSTS); do
		echo "Creating principal ${PRINC} for ${HOST}"
		sudo kadmin -p hadoopadmin/admin -w ${PASSWORD} -q "addprinc -randkey ${PRINC}/${HOST}@${REALM}"
	done
}

function createKeytab() {
# Create a keytab for each host in the cluster.

	for HOST in $(cat $HOSTS); do
		echo "Creating ${PRINC} keytab for ${HOST}"
   		sudo kadmin.local -p hadoopadmin/admin -w  -q "ktadd -norandkey -k /tmp/${PRINC}.${HOST}.keytab ${PRINC}/${HOST}@${REALM}"
	done
}

function distroKeytab() {
# Distribute the keytabs to every node.
	
	for HOST in $(cat $HOSTS); do
		echo "Distributing ${PRINC} keytab to ${HOST}"
   		scp /tmp/${PRINC}.${HOST}.keytab ${HOST}:${HOME}/${PRINC}.keytab
		ssh ${HOST} -C "mv ${HOME}/${PRINC}.keytab /etc/security/keytabs/$PRINC.keytab" < /dev/null
		ssh ${HOST} -C "chown ${PRINC}:hadoop /etc/security/keytabs/${PRINC}.keytab" < /dev/null
		rm /tmp/${PRINC}.${HOST}.keytab
	done
}

function checkKeytab() {
# Test the Hadoop keytab for each HOST in the cluster.
	
	for HOST in $(cat $HOSTS); do
		echo "Listing ${PRINC} keytab on ${HOST}"
		ssh ${HOST} -C "kinit -ket /etc/security/keytabs/${PRINC}.keytab ${PRINC}/${HOST}@${REALM}" 
	done
}

#MAIN
# Source functions
callFunction

# Run checks
checkSudo
checkArg 3

# Create principal
createPrinc
createKeytab
distroKeytab
checkKeytab
