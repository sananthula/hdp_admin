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

# Name: run-remote-admin.sh
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
	echo "Usage: $(basename $0) [connect|rename|icloud|update|reboot|compression]" 
        echo "              	            [resolv <resolv.conf>]"
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

function runConnect() {
# Rename the host name of the node

        echo "Answer 'yes' if asked to remote connect"

        for HOST in $(cat ${HOSTS}); do
                ssh ${HOST} echo "Testing" > /dev/null 2>&1
                if [ $? = "0" ]; then
                        echo "Connected to ${HOST}"
                else
                        echo "Failed to connect to ${HOST}"
                fi
        done
}

function renameHosts() {
# Rename the host name of the node

        for HOST in $(cat ${HOSTS}); do
                echo "Rename host on ${HOST}"
                ssh -t ${HOST} "sudo hostnamectl set-hostname ${HOST}" >> ${LOGFILE} 2>&1
        echo "rename done"
        done
}

function pushICloud() {
# Rename the host name of the node

        for HOST in $(cat ${HOSTS}); do
        echo "Copy iCloud.conf to ${HOST}"
        scp ${HOME}/etc/cloud.cfg ${HOST}:/tmp
        ssh -t ${HOST} "sudo mv /tmp/cloud.cfg /etc/cloud/cloud.cfg"
done
}

function runUpdate() {
# Run a script on the remote nodes

        for HOST in $(cat ${HOSTS}); do
                ssh -tt ${HOST} "sudo yum -y update" >> ${LOGFILE} 2>&1
                echo "Run yum update on ${HOST}" | tee -a ${LOGFILE}
        done
}

function runReboot() {
# Run a script on the remote nodes

        for HOST in $(cat ${HOSTS}); do
                echo "Reboot ${HOST}" | tee -a ${LOGFILE}
                ssh -tt ${HOST} "sudo reboot" >> ${LOGFILE} 2>&1
        done
}

function installCompression() {
# Run a script on the remote nodes

        for HOST in $(cat ${HOSTS}); do
                echo "Run yum install compression on ${HOST}" | tee -a ${LOGFILE}
                ssh -tt ${HOST} "sudo yum -y install snappy snappy-devel"  >> ${LOGFILE} 2>&1
                ssh -tt ${HOST} "sudo yum -y install lzo lzo-devel hadoop-lzo hadoop-lzo-native"  >> ${LOGFILE} 2>&1
        done
}

function pushResolv() {
# push the /etc/resolv.conf file into the remote nodes

	PUSHFILE=${INPUT}
	checkFile ${PUSHFILE}

        for HOST in $(cat ${HOSTS}); do
                scp ${PUSHFILE} ${HOST}:${HOME}  >> ${LOGFILE} 2>&1
                ssh -tt ${HOST} "sudo chattr -i /etc/resolv.conf"  >> ${LOGFILE} 2>&1
                ssh -tt ${HOST} "sudo mv ${HOME}/resolv.conf /etc/resolv.conf"  2>&1 >> ${LOGFILE}
                ssh -tt ${HOST} "sudo chattr +i /etc/resolv.conf" >> ${LOGFILE} 2>&1
		RESULT=$?
		if [ ${RESULT} -eq 0 ]; then
                	echo "Push ${PUSHFILE} to ${HOST}" | tee -a ${LOGFILE}
		else
                	echo "ERROR: Failed to push ${PUSHFILE} to ${HOST}" | tee -a ${LOGFILE}
		fi
        done
}

function runOption() {
# Case statement for options

	case "${OPTION}" in
		-h | --help)
			usage
			;;
                rename)
                        checkArg 1
                        renameHosts
                        ;;
                icloud)
                        checkArg 1
                        pushICloud
                        ;;
                connect)
                        checkArg 1
                        runConnect
			;;
                update)
                        checkArg 1
                        runUpdate
			;;
                reboot)
                        checkArg 1
                        runReboot
			;;
                compression)
                        checkArg 1
                        installCompression
			;;
                resolv)
                        checkArg 2
                        pushResolv
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
