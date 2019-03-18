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

# Name: refresh-services.sh
# Author: WKD
# Date: 14NOV16
# Purpose: Refresh HDFS and YARN for SSSD. 
#
# Note: This script is intended to be run on remote nodes in the cluster

# VARIABLES
NUMARGS=$#
OPTION=$1
AMBARI_USER=$2
AMBARI_PASSWORD=$3
AMBARI_SERVER=$4

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [http|https] [ambari_user] [ambari_password] [ambari_server]" 1>&2
        echo "          	            [yarn]"
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
# Check if arguments exits

        if [ ${NUMARGS} -ne "$1" ]; then
                usage 1>&2
        fi
}

function curlHTTP() {
# curl using http

	OUTPUT=$(curl -u ${AMBARI_USER}:${AMBARI_PASSWORD} -i -s -H 'X-Requested-By: ambari' http://${AMBARI_SERVER}:8080/api/v1/clusters)
}

function curlHTTPS() {
# curl using https

	OUTPUT=$(curl -u ${AMBARI_USER}:${AMBARI_PASSWORD} -i -s -k -H 'X-Requested-By: ambari' https://${AMBARI_SERVER}:8443/api/v1/clusters)
}

function printCluster() {
# print out cluster name

	export CLUSTER=$( echo ${OUTPUT} | sed -n 's/.*"cluster_name" : "\([^\"]*\)".*/\1/p')
	echo ${CLUSTER}
}

function testHDFS() {
# Testing for the HDFS keytab

	if [ ! -f /etc/security/keytabs/hdfs.headless.keytab ]; then
		echo "HDFS keytab not found, did you run this on the namenode?"
		usage
	fi
} 

function refreshHDFS() {
# Refresh user and group mappings with LDAP/AD

	sudo sudo -u hdfs kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs-${CLUSTER}
	sudo sudo -u hdfs hdfs dfsadmin -refreshUserToGroupsMappings
}

function testYARN() {
# Test for YARN keytab

	if [ ! -f /etc/security/keytabs/rm.service.keytab ]; then
		echo "RM keytab not found, did you run this on the ResourceManager node?"
		usage
	fi
} 

function refreshYARN() {
# Run yarn rmadmin to sync the group mappings with LDAP/AD

	sudo sudo -u yarn kinit -kt /etc/security/keytabs/rm.service.keytab rm/$(hostname -f)@LAB.HORTONWORKS.NET
	sudo sudo -u yarn yarn rmadmin -refreshUserToGroupsMappings
}

function runOption() {
# Case statement for option

        case ${OPTION} in
                -h | --help)
                        usage
			;;
                http)
                        checkArg 4
			testHDFS
			curlHTTP
			printCluster
			refreshHDFS
			;;
                https)
                        checkArg 4
			testHDFS
			curlHTTPS
			printCluster
			refreshHDFS
			;;
                yarn)
			checkArg 1
                       	testYARN
			refreshYARN
			;; 
                *)
                        usage
			;;
        esac
}

# MAIN
# Run check
checkSudo

# Run option
runOption
