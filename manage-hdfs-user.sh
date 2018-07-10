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

# Name: manage-hdfs-user.sh
# Author: WKD
# Date: 1MAR18
# Purpose: Script to add, delete or list HDFS users. The script also 
# sets and clears the space quota and the file quota.

# VARIABLES
NUMARGS=$#
OPTION=$1
USERNAME=$2
FILEQ=$3
SPACEQ=$4

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [add <username>]"
        echo "			   [delete <username>]"
        echo "		    	   [list]"
        echo "		   	   [setquota <username> <file_quota> <space_quota> ]"
        echo "		    	   [clearquota <username>]"
        echo "		    	   [listquota <username>]"
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

function addUser() {
# Create hdfs user working directory 

	sudo -u hdfs hdfs dfs -mkdir /user/${USERNAME}
	sudo -u hdfs hdfs dfs -chown ${USERNAME}:hdfs /user/${USERNAME}
}

function deleteUser() {
# Delete hdfs user

	sudo -u hdfs hdfs dfs -rm -r -skipTrash /user/${USERNAME}
}

function listUser() {
# List hdfs users

	sudo -u hdfs hdfs dfs -ls /user
}

function setQuotas() {
# Create hdfs user working directory and set quotas

	sudo -u hdfs hdfs dfsadmin -setQuota ${FILEQ} /user/${USERNAME}
	sudo -u hdfs hdfs dfsadmin -setSpaceQuota ${SPACEQ} /user/${USERNAME}
}

function clearQuotas() {
# Create hdfs user working directory and set quotas

	sudo -u hdfs hdfs dfsadmin -clrQuota /user/${USERNAME}
	sudo -u hdfs hdfs dfsadmin -clrSpaceQuota  /user/${USERNAME}
}

function listQuotas() {
# Create hdfs user working directory and set quotas

	sudo -u hdfs hdfs dfs -count -q /user/${USERNAME}
}

function runOption() {
# Case statement for add or delete user

	case "${OPTION}" in
		-h | --help)
			usage
			;;
		add)
			checkArg 2
			addUser
			;;
		delete)
			checkArg 2
			deleteUser
			;;
		list)
			checkArg 1
			listUser
			;;
		setquota)
			checkArg 4
			setQuotas
			;;
		clearquota)
			checkArg 2
			clearQuotas
			;;
		listquota)
			checkArg 2
			listQuotas
			;;
		*)
			usage
			;;
	esac
}

# MAIN
# Source functions
callFunction

# Run option
runOption
