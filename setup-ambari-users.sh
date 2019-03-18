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

# Name: setup-hdp.sh
# Author: WKD
# Date: 26NOV18
# Purpose: 
#set -x

# VARIABLES
NUMARGS=$#
OPTION=$1
AMBARI_HOST=admin01.hwu.net
AMBARI_URL=http://admin01.hwu.net:8080
AMBARI_USER=admin
AMBARI_PASSWORD=admin
AMBARI_CLUSTER=tantor

# FUNCTIONS
function usage() {
        echo "Usage: $(basename $0) [all|hooks|users|horton|data]"
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

function addHooks() {
# Add hooks for Ambari to create directory in HDFS

	ssh -t centos@${AMBARI_HOST} "echo 'ambari.post.user.creation.hook.enabled=true' | sudo tee -a /etc/ambari-server/conf/ambari.properties > /dev/null"
	ssh -t centos@${AMBARI_HOST} "echo 'ambari.post.user.creation.hook=/var/lib/ambari-server/resources/scripts/post-user-creation-hook.sh' | sudo tee -a /etc/ambari-server/conf/ambari.properties > /dev/null"
	ssh centos@${AMBARI_HOST} 'sudo ambari-server restart'
}

function addUsers() {
# Create Ambari users centos and horton, then assign to groups and roles
# Permissions: CLUSTER.ADMINISTRATOR CLUSTER.OPERATOR SERVICE.ADMINISTRATOR SERVICE.OPERATOR CLUSTER.USER

	# Add users
        curl -i -u ${AMBARI_USER}:${AMBARI_PASSWORD} -H "X-Requested-By: ambari" -X POST -d '{"Users/user_name":"centos","Users/password":"BadPass#1","Users/active":"true", "Users/admin":"true"}' ${AMBARI_URL}/api/v1/users
        curl -i -u ${AMBARI_USER}:${AMBARI_PASSWORD} -H "X-Requested-By: ambari" -X POST -d '{"Users/user_name":"horton","Users/password":"BadPass#1","Users/active":"true", "Users/admin":"false"}' ${AMBARI_URL}/api/v1/users

	# Add groups
        curl -i -u ${AMBARI_USER}:${AMBARI_PASSWORD} -H "X-Requested-By: ambari" -X POST -d '[{"Groups":{"group_name":"hdpadmins"}}]", "Users/admin":"true"}' ${AMBARI_URL}/api/v1/groups
        curl -i -u ${AMBARI_USER}:${AMBARI_PASSWORD} -H "X-Requested-By: ambari" -X POST -d '[{"Groups":{"group_name":"devops"}}]", "Users/admin":"true"}' ${AMBARI_URL}/api/v1/groups

	# Add users to groups
        curl -i -u ${AMBARI_USER}:${AMBARI_PASSWORD} -H "X-Requested-By: ambari" -X POST -d '[{"MemberInfo":{"user_name":"centos"}}]' ${AMBARI_URL}/api/v1/groups/hdpadmins/members
        curl -i -u ${AMBARI_USER}:${AMBARI_PASSWORD} -H "X-Requested-By: ambari" -X POST -d '[{"MemberInfo":{"user_name":"horton"}}]' ${AMBARI_URL}/api/v1/groups/devops/members

	# Assign groups to roles
        curl -i -u ${AMBARI_USER}:${AMBARI_PASSWORD} -H "X-Requested-By: ambari" -X POST -d '[{"PrivilegeInfo":{"permission_name":"CLUSTER.ADMINISTRATOR","principal_name":"hdpadmins","principal_type":"GROUP"}}]' ${AMBARI_URL}/api/v1/clusters/${AMBARI_CLUSTER}/privileges
        curl -i -u ${AMBARI_USER}:${AMBARI_PASSWORD} -H "X-Requested-By: ambari" -X POST -d '[{"PrivilegeInfo":{"permission_name":"SERVICE.ADMINISTRATOR","principal_name":"devops","principal_type":"GROUP"}}]' ${AMBARI_URL}/api/v1/clusters/${AMBARI_CLUSTER}/privileges

	# Disable admin user
        #curl -i -u ${AMBARI_USER}:${AMBARI_PASSWORD} -H "X-Requested-By: ambari" -X POST -d '{"Users/active":"false"}' ${AMBARI_URL}/api/v1/users/admin
}

function setupHorton() {
# Setup the hdfs:/user/horton directory

	ssh -tt centos@admin01 -C "sudo -u hdfs hdfs dfs -chmod 777 /user/horton"
}

function addData() {
# Add the data sets into hdfs:/data

	ssh -tt centos@client01 -C "sudo -u hdfs hdfs dfs -put /home/horton/data /"
}

function runAll() {
	addHooks
	addUsers
	sleep 5
	setupHorton
	addData
}

function runOption() {
# Case statement

        case "${OPTION}" in
                -h | --help)
                        usage
                        ;;
                all)
                        runAll
                        ;;
                hooks)
                       	addHooks 
                        ;;
                users)
                        addUsers
                        ;;
                horton)
                        setupHorton
                        ;;
                data)
                       	addData
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
checkArg 1
checkSudo

# Run option
runOption
