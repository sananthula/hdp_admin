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

# Name: install-kerberos.sh
# Author: WKD  
# Date: 11 Jul 2015
# Purpose: Admin script to assist in managing the Hadoop cluster
# and services. Used to install kerberos through out the cluster 

# CHANGES
# RFC-1274 Script Maintenance 

# VARIABLES
NUMARGS=$#

# FUNCTIONS
function usage() {
	echo "Useage: $(basename $0)" 
	exit 1 
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

function installKerberos() {
# Install Kerberos server and admin

	sudo yum install -y krb5 krb5-workstation pam_krb5 < /dev/null
}

# MAIN 
# Source functions
source ${HOME}/sbin/functions.sh

# Run checks
checkSudo
checkArg

# Run installs
installKerberos
