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

# Name: run-remote-security.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Script to run any script in the user's home directory on 
# every node contained in the node list.  

# VARIABLES
NUMARGS=$#
OPTION=$1
INPUT1=$2
INPUT2=$3
HOSTS=${HOME}/conf/listhosts.txt
PYFILE=cert-verification.cfg
KRBFILE=krb5.conf
LOGDIR=${HOME}/log
DATETIME=$(date +%Y%m%d%H%M)
LOGFILE="${LOGDIR}/run-remote-security-${DATETIME}.log"

# FUNCTIONS
function usage() {
	echo "Usage: $(basename $0) [nonroot]" 
	echo "                        [ldap <AD-ip-address> <AD-password>]" 
	echo "                        [test-ldap <AD-password>]" 
        echo "                        [sssd <Kerberos-password>]"
        echo "                        [spnego]"
        echo "                        [krb5]"
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

function runNonroot() {
# Run the ambari-agent.sh file on all nodes 

        for HOST in $(cat ${HOSTS}); do
                echo "Run the ambari agent script on ${HOST}" | tee -a ${LOGFILE}
                ssh -tt ${HOST} "${HOME}/sbin/install-non-root.sh"  >> ${LOGFILE} 2>&1
        done
	# Restart the Ambari server
        echo "Restart the Ambari server" | tee -a ${LOGFILE}
	sudo ambari-server restart >> ${LOGFILE} 2>&1
}

function runLDAP() {
# Run a script on a remote node 
# Command to run install-ldap.sh with Active Directory IP Address
# Add or remove # 2>$1 >> ${LOGFILE} to trim {OPTION} output

	IP=${INPUT1}
	PASSWORD=${INPUT2}

	for HOST in $(cat ${HOSTS}); do
		echo "Run install-ldap.sh on ${HOST}" | tee -a ${LOGFILE}
		ssh -tt ${HOST} "${HOME}/sbin/install-ldap.sh ${IP} ${PASSWORD}"  >> ${LOGFILE} 2>&1

		if [ $? -eq 1 ]; then
			usage
		fi
	done 
}

function testLDAP() {
# Run a script on a remote node 
# Command to test LDAP

	PASSWORD=${INPUT1}

	for HOST in $(cat ${HOSTS}); do
		echo
		echo "Testing LDAP connection on ${HOST}" | tee -a ${LOGFILE}
		ssh -tt ${HOST} " ldapsearch -w ${PASSWORD} -D ldap-reader@lab.hortonworks.net"  >> ${LOGFILE}  2>&1
		if [ $? -eq 1 ]; then
			usage
		fi
	done 
}

function runSSSD() {
# Run a script on a remote node 
# Command to run install-sssd.sh with Kerberos password 
# Add or remove # 2>$1 >> ${LOGFILE} to trim {OPTION} output

	PASSWORD=${INPUT1}

	for HOST in $(cat ${HOSTS}); do
		echo "Run install-sssd.sh on ${HOST}" | tee -a ${LOGFILE}
		ssh -tt ${HOST} "${HOME}/sbin/install-sssd.sh ${PASSWORD}"  >> ${LOGFILE}  2>&1
		if [ $? -eq 1 ]; then
			usage
		fi
	done 
}

function runSPENGO() {
# Run a script on a remote node 
# Command to copy in the SPNEGO key

	for HOST in $(cat ${HOSTS}); do
		echo "Run SPNEGO key on ${HOST}" | tee -a ${LOGFILE}
		ssh -tt ${HOST} "${HOME}/sbin/config-spnego-key.sh ${PASSWORD}"  >> ${LOGFILE} 2>&1
	done 
}

function pushKRBFile() {
# push the hosts file into remote sbin directory

        for HOST in $(cat ${HOSTS}); do
                echo "Copy hosts file to ${HOST}" | tee -a ${LOGFILE}
                scp ${HOME}/conf/${KRBFILE} ${HOST}:${HOME}/  >> ${LOGFILE} 2>&1
        done
}

function moveKRBFile() {
# move the hosts file into remote /etc directory

        for HOST in $(cat ${HOSTS}); do
                echo "Move hosts file on ${HOST}" | tee -a ${LOGFILE}
                ssh -tt ${HOST} "sudo mv ${HOME}/${KRBFILE} /etc/"  >> ${LOGFILE} 2>&1
        done
}

function runOption() {
# Case statement for option

	case ${OPTION} in
		-h | --help)
			usage
			;;
                nonroot)
                        checkArg 1
			runNonroot 
			;;
                ldap)
                        checkArg 3
			checkIP 
                        runLDAP
			;;
                test-ldap)
                        checkArg 2
                        testLDAP
			;;
                sssd)
                        checkArg 2
                        runSSSD
			;;
                spnego)
                        checkArg 1
                        runSPENGO 
			;;
                krb5)
                        checkArg 1
                        pushKRBFile
			moveKRBFile 
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

# Run options
runOption

# Review log file
echo "Review log file at ${LOGFILE}"
