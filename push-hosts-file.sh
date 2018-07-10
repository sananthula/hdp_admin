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

# Name: push-hosts-file.sh
# Author: WKD
# Date: 14MAR17
# Purpose: Script to push hosts files into the /etc directory of the 
# root user on nodes contained in the nodes list. The node list 
# is a text file read in to a for loop. 

# VARIABLES
NUMARGS=$#
HOSTSFILE=${HOME}/etc/hosts.txt
HOSTS=${HOME}/etc/listhosts.txt
LOGDIR=${HOME}/log
DATETIME=$(date +%Y-%m-%d:%H:%M:%S)
LOGFILE="${LOGDIR}/push-hosts-file-${DATETIME}.log"

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
}

function backupHosts() {
# backup hosts file 

        if [ -f ${HOSTSFILE} ]; then
              	cp ${HOSTSFILE} /tmp
        fi
}

function pushFile() {
# push the hosts file into remote sbin directory 

	for HOST in $(cat ${HOSTS}); do
		echo "Copy hosts file to ${HOST}"
		scp ${HOSTSFILE} ${HOST}:/tmp/hosts >> ${LOGFILE} 2>&1
	done 
}

function moveFile() {
# move the hosts file into remote /etc directory 

	for HOST in $(cat ${HOSTS}); do
		echo "Move hosts file on ${HOST}"
		ssh -t ${HOST} "sudo mv /tmp/hosts /etc/hosts" >> ${LOGFILE} 2>&1
	done 
}

# MAIN
# Source functions
callFunction

# Run checks
checkSudo
checkLogDir
checkArg 1
checkFile ${HOSTS}
checkFile ${HOSTS}
backupHosts

# Move file
pushFile
moveFile
