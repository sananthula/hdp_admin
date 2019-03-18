#!/bin/sh

# Hortonworks University
# This scr{IPADDRESS}t is for training purposes only and is to be used only 
# in support of approved Hortonworks University lab exercises. Hortonworks
# assumes no liability for use outside of our traning environments.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# install-ldap.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Script to install ldap software in support of LDAP/AD. 
# Script requires the input of the LDAP/AD IPADDRESS address and the LDAP/AD
# password. The script loads software, configures the connection, 
# and then runs tests to validate. 
#
# Note: This scripts is intended to be run on every node of the cluster

# VARIABLES
NUMARGS=$#
IPADDRESS=$1
PASSWORD=$2
WRKDIR=${HOME}

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [AD-IP-address] [AD-password]" 1>&2
        exit 1
}

function checkSudo() {
# Testing for sudo access to root

        sudo ls /root > /dev/null
        if [ "$?" != 0 ]; then
                echo "ERROR: You must have sudo to root to run this script"
                usage
        fi
}

function checkArg() {
# Check arguments exits

        if [ ${NUMARGS} -ne "$1" ]; then
                usage
                exit 1 
        fi
}

function validIP() {
# Test an IP address for validity:
# Usage:
#      validate IP address 
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid IP address then echo good; else echo bad; fi
#

	local IP=$1
    	local  STAT=1

    	if [[ ${IP} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        	OIFS=$IFS
        	IFS='.'
        	IP=(${IP})
        	IFS=$OIFS
        	[[ ${IP[0]} -le 255 && ${IP[1]} -le 255 \
            		&& ${IP[2]} -le 255 && ${IP[3]} -le 255 ]]
        	STAT=$?
    	fi

    	return ${STAT}
}

function checkIP() {
# Run the validIP function

	validIP ${IPADDRESS}
	if [ $? -eq 1 ]; then 
		echo "ERROR: Incorrect IP address format"
		usage
		exit 
 	fi
}

function addIP2Hosts() {
# Add AD to hosts file

	grep ad01 /etc/hosts > /dev/null
	if [ $? -eq 1 ]; then
		echo "${IPADDRESS} ad01.lab.hortonworks.net ad01" | sudo tee -a /etc/hosts
	else
		echo "INFO: The active directory host is already set"
	fi
}

function installLDAP() {
# Install openldap package

	sudo yum -y install openldap-clients ca-certificates
	sudo cp ${WRKDIR}/certs/security/ca.crt /etc/pki/ca-trust/source/anchors/hortonworks-net.crt
	sudo update-ca-trust force-enable
	sudo update-ca-trust extract
	sudo update-ca-trust check
}

function configLDAP() {
# Update ldap.conf with our defaults

	sudo tee -a /etc/openldap/ldap.conf > /dev/null << EOF
TLS_CACERT /etc/pki/tls/cert.pem
URI ldaps://ad01.lab.hortonworks.net ldap://ad01.lab.hortonworks.net
BASE dc=lab,dc=hortonworks,dc=net
EOF
}

function testSSL() {
# test connection to AD using openssl client

	echo "Testing connection to AD using the openssl client"
	openssl s_client -connect ad01:636 </dev/null
}

function testLDAP() {
# test connection to AD using ldapsearch 
# when prompted for password, enter: BadPass#1

	echo "Testing ldapsearch using the ldap client"
	ldapsearch -w ${PASSWORD} -D ldap-reader@lab.hortonworks.net
}

# MAIN
# Run checks
checkSudo
checkArg 2
checkIP

# Add to hosts file
addIP2Hosts 

# Install LDAP
installLDAP
configLDAP

# Run tests
# pause "Ready to test SSL? "
testSSL
# pause "Ready to test LDAP? "
#testLDAP
