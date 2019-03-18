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

# Name: run-remote-nodes.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Script to run any script in the user's home directory on 
# every node contained in the node list.  

# VARIABLES
NUMARGS=$#
OPTION=$1
INPUT=$2
HOSTS=${HOME}/conf/listhosts.txt
LOGDIR=${HOME}/log
DATETIME=$(date +%Y%m%d%H%M)
LOGFILE=${LOGDIR}/run-remote-nodes-${DATETIME}.log

# FUNCTIONS
function usage() {
	echo "Usage: $(basename $0) [user] [authorized_key]" 
	exit 
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

function nifiSSH() {
# Setup ssh for NiFi on cluster 

	FILE=${INPUT}
	checkFile ${FILE}

        for HOST in $(cat ${HOSTS}); do
		ssh -t ${HOST} "sudo mkdir /home/nifi/.ssh"
                scp ${FILE} ${HOST}:/home/nifi/.ssh >> ${LOGFILE} 2>&1
		ssh -t ${HOST} "sudo chmod 600 /home/nifi/.ssh/${FILE}"
		ssh -t ${HOST} "sudo chmod 700 /home/nifi/.ssh"
		ssh -t ${HOST} "sudo chown -R nifi:nifi /home/nifi/.ssh"
        done
}

function runOption() {
# Case statement for options

	case "${OPTION}" in
		-h | --help)
			usage
			;;
  		user)
                        checkArg 2
                        nifiSSH 
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

# Run setups
setupLog ${LOGFILE}

# Run option
runOption

# Review log file
echo "Review log file at ${LOGFILE}"
