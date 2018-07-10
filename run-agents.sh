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

# Name: run-agents.sh
# Author: WKD
# Date: 1MAR18
# Purpose: This script restarts all of the ambari agents in the cluster.
# The IP address for the node must be in the node list file. 
# The root user is not required to run this script. Sudo is used
# for the remote commands.
# Changes:

# VARIABLES
NUMARGS=$#
OPTION=$1
HOSTS=${HOME}/etc/listhosts.txt

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [status|start|stop|restart]" 
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

function runAgents() {
# Run the Ambari agents with option 

	for HOST in $(cat ${HOSTS}); do
		echo "Running ambari-agent ${OPTION} on ${HOST}"
		ssh -tt ${HOST} "sudo ambari-agent ${OPTION}"  
	done 
}

function runOption() {
# Case statement for managing Ambari agents 

        case "${OPTION}" in
                -h | --help)
                        usage
			;;
                status|start|restart|stop)
                        runAgents
			;;
                *)
                        usage
			;;
        esac
}

# MAIN
# Source function
callFunction

# Run checks
checkSudo
checkArg 1

# Run option
runOption
