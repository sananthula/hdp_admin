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

# Name: manage-linux-groups.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Add or delete Linux groups in support of HDP. This will 
# add or delete groups on every node in the node list.

# VARIABLES
NUMARGS=$#
OPTION=$1
HOSTS=${HOME}/etc/listhosts.txt
GROUPFILE=${HOME}/etc/listgroups.txt
LOGDIR=${HOME}/log
DATETIME=$(date +%Y%m%d%H%M)
LOGFILE="${LOGDIR}/linux-groups-${DATETIME}.log"

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [add|delete]"
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
}

function addGroups() {
# Add groups contained in the groups file	

	for HOST in $(cat ${HOSTS}); do
		echo "Adding Linux groups on ${HOST}" | tee -a "${LOGFILE}"
		while read -r NEWGROUP; do
			ssh -tt ${HOST} "sudo groupadd ${NEWGROUP}" < /dev/null >> ${LOGFILE} 2>&1
		done < ${GROUPFILE}
	done
}

function deleteGroups() {
# Delete groups contained in the groups file	

	for HOST in $(cat ${HOSTS}); do
		echo "Deleting Linux groups on ${HOST}" | tee -a "${LOGFILE}"
		while read -r NEWGROUP; do
			ssh -tt ${HOST} "sudo groupdel ${NEWGROUP}" < /dev/null >> ${LOGFILE} 2>&1
		done < ${GROUPFILE}
	done
}

function runOption() {
# Case statement for add or delete Linux groups

        case "${OPTION}" in
                -h | --help)
                        usage
			;;
                add)
			checkArg 1
                        addGroups
			;;
                delete)
			checkArg 1
                        deleteGroups
			;;
                *)
                        usage
			;;
        esac
}

# MAIN
# Source functions
callFunction

# Run checks
checkSudo
checkLogDir
checkFile ${GROUPFILE}

# Run option
runOption
