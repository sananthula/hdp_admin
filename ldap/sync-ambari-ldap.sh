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

# Name: sync-ambari-ldap.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Sync Ambari with Active Directory
# This script could be put into a cron job to run on a regular basis.
# See Hortonworks documentation for suggested periodicity.

#VARIABLES
ETCDIR=${HOME}/conf

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [ambari-admin] [password]"
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

function syncLDAP() {
# Sync Ambari with ldap. Uncomment the line you intend to run.

	sudo ambari-server sync-ldap --all
	#sudo ambari-server sync-ldap --existing
	#sudo ambari-server sync-ldap --groups ${ETCDIR}/syncgroups.txt
}

# MAIN
# Uncomment this line for exercise purposes
# echo "hadoop-users,hr,sales,legal,hadoop-admins" > ${ETCDIR}/syncgroups.txt 
# Source functions
callFunction

# Run checks
checkSudo
checkFile ${ETCDIR}/syncgroups.txt

# Sync LDAP
syncLDAP
