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

# Name: manage-linux-users.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Create or delete Linux power users in support of HDP. This 
# script will create and delete users for every node in the node list.

# VARIABLES
NUMARGS=$#
OPTION=$1
HOSTS=${HOME}/conf/listhosts.txt
USERS=${HOME}/conf/listusers.txt
LOGDIR=${HOME}/log
DATETIME=$(date +%Y%m%d%H%M)
LOGFILE="${LOGDIR}/linux-users-${DATETIME}.log"

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [add|adddb|delete]"
        exit 1
}

function callInclude() {
# Test for script and run functions

        if [ -f ${HOME}/sbin/include.sh ]; then
                source ${HOME}/sbin/include.sh
        else
                echo "ERROR: The file ${HOME}/sbin/include.sh not found."
                echo "This required file provides supporting functions."
        fi
}

function addUsers() {
# use this CLI for standard users

	#echo -n "Create user accounts?"
	#checkcontinue

	for HOST in $(cat ${HOSTS}); do
		echo "Creating user accounts on ${HOST}"
		while IFS=: read -r NEWUSER NEWGROUP; do
			ssh -tt ${HOST} "sudo useradd -d /home/${NEWUSER} -g ${NEWGROUP} -m ${NEWUSER}" < /dev/null  >> ${LOGFILE} 2>&1
		done < ${USERS}
	done
}

function addDBUsers() {
# use this CLI for nologin db users

	#echo -n "Create db user accounts?"
	#checkcontinue

	for HOST in $(cat ${HOSTS}); do
		echo "Creating db user accounts on ${HOST}"
		while IFS=: read -r NEWUSER NEWGROUP; do
        		ssh -tt ${HOST} "sudo useradd -d /var/lib/${NEWUSER} -g ${NEWGROUP} -M -r -s /sbin/nologin ${NEWUSER}" < /dev/null >> ${LOGFILE} 2>&1
		done < ${USERS}
	done
}

function deleteUsers() {
	#echo -n "Delete user accounts?"
	#checkcontinue
	
	for HOST in $(cat ${HOSTS}); do
		echo "Deleting user accounts on ${HOST}"
		while IFS=: read -r NEWUSER NEWGROUP; do
			ssh -tt ${HOST} "sudo userdel -r ${NEWUSER}" < /dev/null >> ${LOGFILE} 2>&1
		done < ${USERS}
	done
}

function runOption() {
# Case statement for add or delete Linux users

        case "${OPTION}" in
                -h | --help)
                        usage
			;;
                add)
			checkArg 1
                        addUsers
			;;
		adddb)
			checkArg 1
			addDBUsers
			;;
                delete)
			checkArg 1
                        deleteUsers
			;;
                *)
                        usage
			;;
        esac
}

# MAIN
# Source functions
callInclude

# Run checks
checkSudo
checkLogDir
checkFile ${USERS}
checkFile ${HOSTS}

# Run option
runOption
