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
HOSTS=${HOME}/etc/listhosts.txt
LOGDIR=${HOME}/log
DATETIME=$(date +%Y%m%d%H%M)
LOGFILE=${LOGDIR}/run-remote-nodes-${DATETIME}.log

# FUNCTIONS
function usage() {
	echo "Usage: $(basename $0)[push <file_name>]" 
        echo "                          [extract <tar-file>]"
        echo "                          [run <remote_script>]"
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

function pushFile() {
# push a file into remote node

	FILE=${INPUT}
	checkFile ${FILE}

        for HOST in $(cat ${HOSTS}); do
                scp ${FILE} ${HOST}:${HOME} >> ${LOGFILE} 2>&1
		RESULT=$?
		if [ ${RESULT} -eq 0 ]; then
                	echo "Push ${FILE} to ${HOST}" | tee -a ${LOGFILE}
		else
                	echo "ERROR: Failed to push ${FILE} to ${HOST}" | tee -a ${LOGFILE}
		fi
        done
}

function runTar() {
# Run a script on a remote node
# Command to extract a tar file in the working directory 

	FILE=${INPUT}

	for HOST in $(cat ${HOSTS}); do
		ssh -tt ${HOST} "tar xf ${FILE}"  >> ${LOGFILE} 2>&1
		RESULT=$?
		if [ ${RESULT} -eq 0 ]; then
			echo "Run tar extract ${FILE} on ${HOST}" | tee -a ${LOGFILE}
		else
			echo "ERROR: Failed to tar extract ${FILE} on ${HOST}" | tee -a ${LOGFILE}
		fi
	done 
}

function runScript() {
# Run a script on a remote node

	FILE=${INPUT}

        for HOST in $(cat ${HOSTS}); do
                ssh -tt ${HOST} "${FILE}" >> ${LOGFILE} 2>&1
		RESULT=$?
		if [ ${RESULT} -eq 0 ]; then
                	echo "Run ${FILE} on ${HOST}" | tee -a ${LOGFILE}
		else
                	echo "ERROR: Failed to run ${FILE} on ${HOST}" | tee -a ${LOGFILE}
		fi
        done
}

function removeFile() {
# Run a script on a remote node
# Command to remove a file in the working directory 

	FILE=${INPUT}

	for HOST in $(cat ${HOSTS}); do
		ssh -tt ${HOST} "rm -r ${FILE}"  >> ${LOGFILE} 2>&1
		RESULT=$?
		if [ ${RESULT} -eq 0 ]; then
			echo "Removed ${FILE} on ${HOST}" | tee -a ${LOGFILE}
		else
                	echo "ERROR: Failed to remove ${FILE} on ${HOST}" | tee -a ${LOGFILE}
		fi
        done
}

function runOption() {
# Case statement for options

	case "${OPTION}" in
		-h | --help)
			usage
			;;
  		push)
                        checkArg 2
                        pushFile
			;;
                extract)
                        checkArg 2
                        runTar
			;;
                run)
                        checkArg 2
                        runScript
			;;
                remove)
                        checkArg 2
                        removeFile
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

# Run setups
setupLog ${LOGFILE}

# Run option
runOption

# Review log file
echo "Review log file at ${LOGFILE}"
