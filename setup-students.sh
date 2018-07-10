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

# Name: setup-students.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Setup students working directories by securing copying a 
# tar file and then extracting it. Additionally copying the private key
# and setting up bashrc.

# VARIABLES
NUMARGS=$#
OPTION=$1
TARFILE=$2
HOSTFILE=${HOME}/etc/liststudents.txt

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [all|tarfile] [tar_file]"
        echo "Usage: $(basename $0) [ssh|bash]"
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

function copyFile() {
# Copy the named file to the students hosts

	echo "Secure copy tar file into ${HOST}"
	scp ${TARFILE} ${HOST}:${HOME}/tmp.tar
}

function extractFile() {
# Extract a file on the students hosts

	echo "Extracting tar ${TARFILE} into ${HOST}"
	ssh -tt ${HOST} -C "tar xvf ~/tmp.tar"
}

function removeFile() {
# Remove a file on the students hosts

	echo "Removing tar {FILE} for ${HOST}"
	ssh -tt ${HOST} -C "\rm ${HOME}/tmp.tar;
		find ${HOME} -name \"Icon\" -exec rm {} \; ;
		find ${HOME} -name \"._Icon\" -exec rm -r {} \;"
}

function sshFile() {
# Copy in the private key on the students hosts

        echo "Setting up ssh for ${USER} for ${HOST}"
        ssh ${HOST} -C "cp ${HOME}/certs/hwu/id_rsa ${HOME}/.ssh;
        	chmod 600 ${HOME}/.ssh/id_rsa"
}

function bashFile() {
# Copy in the bash files on the students hosts

        echo "Setting up bash for ${USER} for ${HOST}"
        ssh -tt ${HOST} -C "cp ${HOME}/etc/bash_profile ${HOME}/.bash_profile;
        	cp ${HOME}/etc/bashrc ${HOME}/.bashrc"
}

function installSoftware() {
# Install software on the students hosts

	ssh -tt ${HOST} -C "sudo yum -y install vim"
}

function allLoop() {
	for HOST in $(cat ${HOSTFILE}); do
		echo "Configuring ${HOST}"
		copyFile
		extractFile
		removeFile
		installSoftware
		sshFile
		bashFile
		echo
	done
}

function tarLoop() {
	for HOST in $(cat ${HOSTFILE}); do
		echo "Configuring ${HOST}"
		copyFile
		extractFile
		removeFile
		echo
	done
}

function sshLoop() {
	for HOST in $(cat ${HOSTFILE}); do
		echo "Configuring ${HOST}"
		sshFile
		sshConfig
		echo
	done
}

function bashLoop() {
	for HOST in $(cat ${HOSTFILE}); do
		echo "Configuring ${HOST}"
		bashFile	
		echo
	done
}

function runOption() {
# Case statement for option to move tarfile or to install bashrc 

        case "${OPTION}" in
                -h | --help)
                        usage
                        ;;
                all)
                        checkArg 2
			checkFile ${FILE}
                        allLoop
                        ;;
                tarfile)
                        checkArg 2
			checkFile ${FILE}
                        tarLoop
                        ;;
                ssh)
                        checkArg 1
                        sshLoop
                        ;;
                bash)
                        checkArg 1
                        bashLoop
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

# Run option
runOption
