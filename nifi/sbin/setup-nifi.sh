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

# Name: setup-nifi.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script either starts up the ambari-server for NiFi instances
# or it installs a workaround for accessing AWS instances called shellinabox. 
#set -x

# VARIABLES
NUMARGS=$#
OPTION=$1
TARFILE=$2
HOSTFILE=./listhosts.txt

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [tar] [tar_file]"
        echo "Usage: $(basename $0) [ambari|shell]"
        exit
}

function checkArg() {
# Check if arguments exits

        if [ ${NUMARGS} -ne "$1" ]; then
                usage
        fi
}

function checkFile() {
# Check for a file

        FILE=$1
        if [ ! -f ${FILE} ]; then
                echo "ERROR: Input file ${FILE} not found"
                usage
        fi
}

function copyTar() {
# Copy the named file to the students hosts

	echo "Secure copy tar file into ${HOST}"
	scp ${TARFILE} root@${HOST}:/root/nifi.tar
}

function extractTar() {
# Extract a file on the students hosts

	echo "Extracting tar ${TARFILE} into ${HOST}"
	ssh -tt root@${HOST} -C "tar xvf /root/nifi.tar"
}

function startAmbari() {
# Copy in the bash files on the students hosts

        echo "Run start Ambari Server for ${HOST}"
        ssh -tt root@${HOST} -C "/root/sbin/start-nifi.sh"
}

function setRoot() {
        echo "Set root password for ${HOST}"
        ssh -tt root@${HOST} -C 'echo "root:D3skt0p" | chpasswd'
}

function installShell() {
# install the shellinabox software

        echo "Run install shell for ${HOST}"
        ssh -tt root@${HOST} -C "/root/sbin/install-shellinabox.sh"
}

function tarLoop() {
	for HOST in $(cat ${HOSTFILE}); do
		echo "Installing sbin on ${HOST}"
		copyTar
		extractTar
		echo
	done
}

function ambariLoop() {
	for HOST in $(cat ${HOSTFILE}); do
		echo "Starting Ambari Server on ${HOST}"
		startAmbari
		echo
	done
}

function shellLoop() {
	for HOST in $(cat ${HOSTFILE}); do
		echo "Installing Shellinabox on ${HOST}"
		installShell
		echo
	done
}

function rootLoop() {
	for HOST in $(cat ${HOSTFILE}); do
		setRoot
	done
}

function runOption() {
# Case statement for option to move tarfile or to install bashrc 

        case "${OPTION}" in
                -h | --help)
                        usage
                        ;;
                tar)
			checkFile ${TARFILE}
			checkArg 2
                        tarLoop
                        ;;
                ambari)
			checkArg 1
                        ambariLoop
                        ;;
                shell)
			checkArg 1
                        shellLoop
                        ;;
                root)
			checkArg 1
                        rootLoop
                        ;;
                *)
                        usage
                        ;;
        esac
}

# MAIN

# Run option
runOption
