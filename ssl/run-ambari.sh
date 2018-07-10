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

# Title: run-ambari.sh
# Author: WKD and Validmir Zlatkin
# Date: 1MAR18
# Purpose: This script setups Ambari SSL encryption and the Ambari
# truststore. 
# Note: This script must be run on the Ambari server.

# VARIABLE
NUMARGS=$#
OPTION=$1
SSLDIR=${HOME}/sbin/ssl
WRKDIR=${HOME}/pki

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

function showMenu() {
        clear
        headingSSL

        echo "

 1. Setup HTTPS for Ambari Server
 2. Setup truststore for Ambari Server

"
        read -p "Enter your selection (q to quit): " OPTION junk;

        # If there is an empty {OPTION} (Pressing ENTER) redisplays
        [ "${OPTION}" = "" ] && continue
}

function runOption() {
# Case statement for option
        case ${OPTION} in
                -h | --help)

                        usage
                        ;;
                1)
           		setPKIPass
			${SSLDIR}/setup-ambari-https.sh
                        ;;
                2)
           		setPKIPass
			${SSLDIR}/setup-ambari-jks.sh
			;;
                q*|Q*)
                        clear;
                        exit 0
                        ;;
                *)
			echo "Incorrect entry, please try again"
                        ;;
        esac
}

function runMenu() {
# Run the menu in a while loop

        while true; do
                showMenu
                runOption
                pause
        done
}

# MAIN
# Source functions
callFunction

# Run checks
checkSudo
checkArg 0
checkAmbari

# Run setups

# Run expect scripts
runMenu
