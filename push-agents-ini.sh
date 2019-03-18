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

# Name: push-agents-ini.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Script to push ambari-agents.ini file into the 
# /etc/ambari-agent/conf directory of the nodes contained in the 
# nodes list. The node list is a text file. 

# VARIABLES
NUMARGS=$#
PUSHFILE=${HOME}/conf/ambari-agent.ini
HOSTS=${HOME}/conf/listhosts.txt
LOGDIR=${HOME}/log
DATETIME=$(date +%Y%m%d%H%M)
LOGFILE="${LOGDIR}/push-agents-${DATETIME}.log"

# FUNCTIONS
function usage() {
	echo "Usage: $(basename $0)" 
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

function pushFile() {
# push the file into remote directory 

	for HOST in $(cat ${HOSTS}); do
		echo "Copy the file to ${HOST}"
		scp ${PUSHFILE} ${HOST}:/tmp/ambari-agent.ini >> ${LOGFILE} 2>&1
	done 
}

function moveFile() {
# move the file into remote /etc directory 

	for HOST in $(cat ${HOSTS}); do
		echo "Move the file on ${HOST}"
		ssh -tt ${HOST} "sudo mv /tmp/ambari-agent.ini /etc/ambari-agent/conf/ambari-agent.ini" >> ${LOGFILE} 2>&1
	done 
}

# MAIN
# Source functions
callInclude

# Run checks
checkSudo
checkLogDir
checkArg 0
checkFile ${PUSHFILE}
checkFile ${HOSTS}

# Move file
pushFile
moveFile
